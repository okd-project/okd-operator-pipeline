###########################################################################
# Istio Pilot build                                                       #
###########################################################################

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS gobuilder

ARG ISTIO_GIT_TAG
ARG ISTIO_GIT_SHA

COPY --chown=default istio .

ENV CGO_ENABLED=1
ENV GOFLAGS="-mod=readonly"
# Using '_' so we don't have to deal with "Unexpected istiod version" test failures in operator e2e suite
# See https://github.com/istio-ecosystem/sail-operator/blob/mwwwwwwwwwwwwwwwwwwwwwwwwain/tests/e2e/controlplane/control_plane_test.go#L50
ENV LDFLAGS="\
-X istio.io/istio/pkg/version.buildVersion=${ISTIO_GIT_TAG}_ossm \
-X istio.io/istio/pkg/version.buildGitRevision=${ISTIO_GIT_SHA} \
-X istio.io/istio/pkg/version.buildTag=${ISTIO_GIT_TAG}_ossm \
-X istio.io/istio/pkg/version.buildStatus=Clean \
-s -w"

RUN mkdir /tmp/out

RUN go version

RUN go build -ldflags "-B 0x$(head -c20 /dev/urandom|od -An -tx1|tr -d ' \n') ${LDFLAGS:-}" \
    -tags strictfipsruntime \
    -o /tmp/out/pilot-discovery ./pilot/cmd/pilot-discovery

RUN cp ./tools/packaging/common/envoy_bootstrap.json /tmp/out/envoy_bootstrap.json

###########################################################################
# Istio Pilot image                                                       #
###########################################################################

FROM quay.io/centos/centos:stream9-minimal AS release

ARG ISTIO_GIT_TAG
ARG ISTIO_GIT_SHA
ARG ISTIO_GIT_URL

# Name must match the repository name
LABEL com.github.url="${ISTIO_GIT_URL}"
LABEL com.github.commit="${ISTIO_GIT_SHA}"
LABEL summary="OKD Service Mesh Pilot OKD container image"
LABEL description="OKD Service Mesh Pilot OKD container image"
LABEL version="${ISTIO_GIT_TAG}"
LABEL istio_version="${ISTIO_GIT_TAG}"
LABEL io.k8s.display-name="OKD Service Mesh Pilot"
LABEL io.k8s.description="OKD Service Mesh Pilot OKD container image"

ENV ISTIO_VERSION="${ISTIO_GIT_TAG}"
ENV container="oci"

RUN mkdir -p /var/lib/istio/envoy
RUN mkdir -p /etc/istio/proxy
RUN chmod g+w /etc/istio/proxy

COPY --from=gobuilder /tmp/out/envoy_bootstrap.json /var/lib/istio/envoy/envoy_bootstrap_tmpl.json
COPY --from=gobuilder /tmp/out/pilot-discovery /usr/local/bin

# Copy the Istio license
COPY istio/LICENSE /licenses/LICENSE

# Workaround for https://github.com/istio/istio/pull/5798
RUN ln -s /etc/pki/tls/cert.pem /cacert.pem

WORKDIR /

# Ensure we do not run as root
USER 1000

ENTRYPOINT [ "/usr/local/bin/pilot-discovery" ]
