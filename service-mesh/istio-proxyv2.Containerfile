###########################################################################
# Istio Pilot Agent build                                                 #
###########################################################################

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS gobuilder

ARG ISTIO_GIT_TAG
ARG ISTIO_GIT_SHA

COPY --chown=default istio proxy-scripts/build-pilot-agent.sh ./

RUN go version

RUN bash build-pilot-agent.sh

###########################################################################
# Istio Proxy build                                                       #
###########################################################################

# automatically updated by renovate
FROM quay.io/redhat-user-workloads/service-mesh-tenant/ossm-3-0-proxy-debug@sha256:5bdb520ce92a65ecf192a261f3dc13f368cc6fe090b429a85f5299ba9725d68e AS proxy_debug

# stripping proxy needs root privileges
USER 0

# strip debugsymbols
RUN strip /proxy/bazel-bin/envoy

###########################################################################
# Istio Proxy image                                                       #
###########################################################################

FROM quay.io/centos/centos:stream9-minimal AS release

ARG PROXY_GIT_TAG
ARG PROXY_GIT_SHA
ARG PROXY_GIT_URL

# Name must match the repository name
LABEL com.github.url="${PROXY_GIT_URL}"
LABEL com.github.commit="${PROXY_GIT_SHA}"
LABEL summary="OKD Service Mesh Proxy V2 OKD container image"
LABEL description="OKD Service Mesh Proxy V2 OKD container image"
LABEL version="${PROXY_GIT_TAG}"
LABEL istio_version="${PROXY_GIT_TAG}"
LABEL io.k8s.display-name="OKD Service Mesh Proxy V2"
LABEL io.k8s.description="OKD Service Mesh Proxy V2 OKD container image"

ENV ISTIO_VERSION="${PROXY_GIT_TAG}"
ENV container="oci"

# Environment variables indicating this proxy's version/capabilities as opaque string
# ISTIO_META_ISTIO_PROXY_VERSION and ISTIO_META_ISTIO_VERSION need to match
ENV ISTIO_META_ISTIO_PROXY_VERSION="${PROXY_GIT_TAG}"
# Environment variable indicating the exact proxy sha - for debugging or version-specific configs
ENV ISTIO_META_ISTIO_PROXY_SHA="${PROXY_GIT_SHA}"
# Environment variable indicating the exact build, for debugging
ENV ISTIO_META_ISTIO_VERSION="${PROXY_GIT_TAG}"

# Install openssl library
RUN microdnf install -y openssl && microdnf clean all
RUN ln -s /usr/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so && ln -s /usr/lib64/libssl.so.3 /usr/lib64/libssl.so

COPY --from=gobuilder /tmp/out/pilot-agent /usr/local/bin/pilot-agent
COPY --from=gobuilder /tmp/out/envoy_bootstrap.json /var/lib/istio/envoy/envoy_bootstrap_tmpl.json
COPY --from=proxy_debug /proxy/bazel-bin/envoy /usr/local/bin/envoy

# WASM extensions
COPY --from=proxy_debug /proxy/bazel-bin/extensions/stats.wasm /etc/istio/extensions/stats-filter.wasm
COPY --from=proxy_debug /proxy/bazel-bin/extensions/stats.compiled.wasm /etc/istio/extensions/stats-filter.compiled.wasm

COPY --from=proxy_debug /proxy/bazel-bin/extensions/metadata_exchange.wasm /etc/istio/extensions/metadata-exchange-filter.wasm
COPY --from=proxy_debug /proxy/bazel-bin/extensions/metadata_exchange.compiled.wasm /etc/istio/extensions/metadata-exchange-filter.compiled.wasm

# Container image needs to contain licensing info
COPY proxy/LICENSE /licenses/LICENSE

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

