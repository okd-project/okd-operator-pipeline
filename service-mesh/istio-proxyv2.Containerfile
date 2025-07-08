ARG SHORT_VERSION
###########################################################################
# Istio Pilot Agent build                                                 #
###########################################################################

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS gobuilder

ARG VERSION
ARG ISTIO_REVISION

COPY --chown=default service-mesh/istio .

RUN mkdir /tmp/out
ENV CGO_ENABLED=1
ENV LDFLAGS="\
-X istio.io/istio/pkg/version.buildVersion=${VERSION} \
-X istio.io/istio/pkg/version.buildGitRevision=${ISTIO_REVISION} \
-X istio.io/istio/pkg/version.buildTag=${VERSION} \
-X istio.io/istio/pkg/version.buildStatus=Clean \
-s -w"

RUN go build -ldflags "-B 0x$(head -c20 /dev/urandom|od -An -tx1|tr -d ' \n') ${LDFLAGS:-}" \
       -o /tmp/out ./pilot/cmd/pilot-agent

RUN cp ./tools/packaging/common/envoy_bootstrap.json /tmp/out/envoy_bootstrap.json

###########################################################################
# Istio Proxy build                                                       #
###########################################################################

FROM quay.io/maistra-dev/maistra-builder:${SHORT_VERSION} AS proxy_debug

ENV BAZEL_DISK_CACHE=/work/bazel-cache

COPY .git .git
COPY service-mesh/proxy service-mesh/proxy

WORKDIR /work/service-mesh/proxy

#RUN bash ./ossm/ci/common.sh && \
#    bazel build @envoy//test/tools/wee8_compile:wee8_compile_tool && \
#    mv ./bazel-bin/external/envoy/test/tools/wee8_compile/wee8_compile_tool ./wee8_compile_tool

RUN ./ossm/ci/pre-submit.sh

#RUN ./wee8_compile_tool extensions/stats.wasm extensions/stats.compiled.wasm && \
#    ./wee8_compile_tool extensions/metadata_exchange.wasm extensions/metadata_exchange.compiled.wasm

# stripping proxy needs root privileges
USER 0

# strip debugsymbols
RUN strip /work/service-mesh/proxy/bazel-bin/envoy

###########################################################################
# Istio Proxy image                                                       #
###########################################################################

FROM quay.io/centos/centos:stream9-minimal AS release

ARG VERSION
ARG ISTIO_REVISION

# Name must match the repository name
LABEL com.github.commit="${ISTIO_REVISION}"
LABEL summary="OKD Service Mesh Proxy V2 OKD container image"
LABEL description="OKD Service Mesh Proxy V2 OKD container image"
LABEL version="${VERSION}"
LABEL istio_version="${VERSION}"
LABEL io.k8s.display-name="OKD Service Mesh Proxy V2"
LABEL io.k8s.description="OKD Service Mesh Proxy V2 OKD container image"

ENV ISTIO_VERSION="${VERSION}"
ENV container="oci"

# Environment variables indicating this proxy's version/capabilities as opaque string
# ISTIO_META_ISTIO_PROXY_VERSION and ISTIO_META_ISTIO_VERSION need to match
ENV ISTIO_META_ISTIO_PROXY_VERSION="${VERSION}"
# Environment variable indicating the exact proxy sha - for debugging or version-specific configs
ENV ISTIO_META_ISTIO_PROXY_SHA="${ISTIO_REVISION}"
# Environment variable indicating the exact build, for debugging
ENV ISTIO_META_ISTIO_VERSION="${VERSION}"

# Install openssl library
RUN microdnf install -y openssl && microdnf clean all
RUN ln -s /usr/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so && ln -s /usr/lib64/libssl.so.3 /usr/lib64/libssl.so

COPY --from=gobuilder /tmp/out/pilot-agent /usr/local/bin/pilot-agent
COPY --from=gobuilder /tmp/out/envoy_bootstrap.json /var/lib/istio/envoy/envoy_bootstrap_tmpl.json
COPY --from=proxy_debug /work/service-mesh/proxy/bazel-bin/envoy /usr/local/bin/envoy

# WASM extensions
#COPY --from=proxy_debug /proxy/bazel-bin/extensions/stats.wasm /etc/istio/extensions/stats-filter.wasm
#COPY --from=proxy_debug /proxy/bazel-bin/extensions/stats.compiled.wasm /etc/istio/extensions/stats-filter.compiled.wasm
#
#COPY --from=proxy_debug /proxy/bazel-bin/extensions/metadata_exchange.wasm /etc/istio/extensions/metadata-exchange-filter.wasm
#COPY --from=proxy_debug /proxy/bazel-bin/extensions/metadata_exchange.compiled.wasm /etc/istio/extensions/metadata-exchange-filter.compiled.wasm

# Container image needs to contain licensing info
COPY service-mesh/proxy/LICENSE /licenses/LICENSE

# Pilot-agent and envoy may run with effective uid 0 in order to run envoy with
# CAP_NET_ADMIN, so any iptables rule matching on "-m owner --uid-owner
# istio-proxy" will not match connections from those processes anymore.
# Instead, rely on the process's effective gid being istio-proxy and create a
# "-m owner --gid-owner istio-proxy" iptables rule in istio-iptables.sh.
# TODO: disabling due to https://github.com/istio/istio/issues/5745
# RUN \
# chgrp 1337 /usr/local/bin/envoy /usr/local/bin/pilot-agent && \
# chmod 2755 /usr/local/bin/envoy /usr/local/bin/pilot-agent

# Allow running the container with a random uid, as long as it's a member of the root group
# (as is the case when running in openshift without the "anyuid" security context constraint)
RUN mkdir -p /etc/istio/proxy && \
    chmod g+w /etc/istio/proxy

# Ensure we do not run as root
USER 1000

# The pilot-agent will bootstrap Envoy.
ENTRYPOINT ["/usr/local/bin/pilot-agent"]

