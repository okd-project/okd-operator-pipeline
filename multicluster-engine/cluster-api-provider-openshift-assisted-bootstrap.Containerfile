# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder
ARG TARGETOS
ARG TARGETARCH
ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=cluster-api-provider-openshift-assisted-bootstrap
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

WORKDIR /opt/app-root/src

# Copy the Go Modules manifests
COPY --chown=default cluster-api-provider-openshift-assisted/go.mod go.mod
COPY --chown=default cluster-api-provider-openshift-assisted/go.sum go.sum
COPY --chown=default cluster-api-provider-openshift-assisted/vendor vendor

# Copy the go source
COPY --chown=default cluster-api-provider-openshift-assisted/bootstrap/main.go bootstrap/main.go
COPY --chown=default cluster-api-provider-openshift-assisted/bootstrap/api/ bootstrap/api/
COPY --chown=default cluster-api-provider-openshift-assisted/controlplane/api/ controlplane/api/
COPY --chown=default cluster-api-provider-openshift-assisted/util util
COPY --chown=default cluster-api-provider-openshift-assisted/pkg pkg
COPY --chown=default cluster-api-provider-openshift-assisted/assistedinstaller assistedinstaller
COPY --chown=default cluster-api-provider-openshift-assisted/bootstrap/internal/ bootstrap/internal/

# Build
# the GOARCH has not a default value to allow the binary be built according to the host where the command
# was called. For example, if we call make docker-build in a local env which has the Apple Silicon M1 SO
# the docker BUILDPLATFORM arg will be linux/arm64 when for Apple x86 it will be linux/amd64. Therefore,
# by leaving it empty we can ensure that the container and binary shipped on it will have the same platform.
RUN CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} go build -mod=vendor -a -o manager bootstrap/main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
WORKDIR /
COPY --from=builder /opt/app-root/src/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]
