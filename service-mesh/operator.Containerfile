###########################################################################
# Service Mesh Operator build                                             #
###########################################################################

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS gobuilder

ARG SAIL_OPERATOR_GIT_TAG
ARG SAIL_OPERATOR_GIT_SHA

COPY --chown=default operator .

ENV CGO_ENABLED=1
ENV GO111MODULE=on
ENV VERSION="${SAIL_OPERATOR_GIT_TAG}"
ENV GIT_REVISION="${SAIL_OPERATOR_GIT_SHA}"
ENV GITSTATUS=Clean
ENV GIT_TAG="${SAIL_OPERATOR_GIT_TAG}"
ENV BUILD_WITH_CONTAINER=0
ENV GOFLAGS="-mod=readonly"

# TODO: do we want to call make target or call 'go build' directly here for simplicity and to properly control flags?
RUN go version && \
    make -e IS_FIPS_COMPLIANT=true GOBUILDFLAGS_ARRAY="-tags strictfipsruntime" build

###########################################################################
# Service Mesh Operator image                                             #
###########################################################################

FROM quay.io/centos/centos:stream9-minimal AS release

ARG SAIL_OPERATOR_GIT_TAG
ARG SAIL_OPERATOR_GIT_SHA
ARG SAIL_OPERATOR_GIT_URL

# Name must match the repository name
LABEL com.github.url="${SAIL_OPERATOR_GIT_URL}"
LABEL com.github.commit="${SAIL_OPERATOR_GIT_SHA}"
LABEL summary="OKD Service Mesh Operator OpenShift container image"
LABEL description="OKD Service Mesh Operator OpenShift container image"
LABEL version="${SAIL_OPERATOR_GIT_TAG}"
LABEL io.k8s.display-name="OKD Service Mesh Operator"
LABEL io.k8s.description="OKD Service Mesh Operator OKD container image"

ENV container="oci"

# Make build creates a repo structure based on OS and ARCH
COPY --from=gobuilder /opt/app-root/src/out/*_*/sail-operator /usr/local/bin/
COPY --from=gobuilder /opt/app-root/src/resources /var/lib/sail-operator/resources

# Copy the Sail operator license
COPY operator/LICENSE /licenses/LICENSE

# Ensure we do not run as root
USER 1000

WORKDIR /tmp/

ENTRYPOINT [ "/usr/local/bin/sail-operator" ]
