FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-managed-serviceaccount
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default managed-serviceaccount .

RUN go env
RUN go build -tags strictfipsruntime -a -o msa cmd/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/msa /

LABEL summary="multicluster-engine-managed-serviceaccount" \
      io.k8s.display-name="multicluster-engine-managed-serviceaccount" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-managed-serviceaccount"
