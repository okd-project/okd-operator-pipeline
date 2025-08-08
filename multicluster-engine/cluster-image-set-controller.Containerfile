FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-cluster-image-set-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default cluster-image-set-controller .

RUN go build -o bin/clusterimageset cmd/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# cluster-image-set-controller
COPY --from=builder /opt/app-root/src/bin/clusterimageset .

LABEL summary="multicluster-engine-cluster-image-set-controller" \
      io.k8s.display-name="multicluster-engine-cluster-image-set-controller" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-cluster-image-set-controller"
