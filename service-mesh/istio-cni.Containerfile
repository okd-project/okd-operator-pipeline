###########################################################################
# Istio CNI build                                                         #
###########################################################################

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS gobuilder

ARG ISTIO_GIT_TAG
ARG ISTIO_GIT_SHA

COPY --chown=default istio .

ENV CGO_ENABLED=1
ENV GOFLAGS="-mod=readonly"
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
    -o /tmp/out ./cni/cmd/istio-cni ./cni/cmd/install-cni

###########################################################################
# Istio CNI image                                                         #
###########################################################################

FROM quay.io/centos/centos:stream9-minimal AS release

ARG ISTIO_GIT_TAG
ARG ISTIO_GIT_SHA
ARG ISTIO_GIT_URL

# Name must match the repository name
LABEL com.github.url="${ISTIO_GIT_URL}"
LABEL com.github.commit="${ISTIO_GIT_SHA}"
LABEL summary="OKD Service Mesh CNI plugin installer OKD container image"
LABEL description="OKD Service Mesh CNI plugin installer OKD container image"
LABEL version="${ISTIO_GIT_TAG}"
LABEL istio_version="${ISTIO_GIT_TAG}"
LABEL io.k8s.display-name="OKD Service Mesh CNI plugin installer"
LABEL io.k8s.description="OKD Service Mesh CNI plugin installer OKD container image"

ENV ISTIO_VERSION="${ISTIO_GIT_TAG}"
ENV container="oci"

RUN mkdir -p /opt/cni/bin

# OSSM-8227
RUN microdnf install -y iptables && microdnf clean all

COPY --from=gobuilder /tmp/out/install-cni /usr/local/bin
COPY --from=gobuilder /tmp/out/istio-cni /opt/cni/bin

# Copy the Istio license
COPY istio/LICENSE /licenses/LICENSE

# Ensure we do not run as root
USER 1000

ENTRYPOINT ["/usr/local/bin/install-cni"]

