FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-cluster-api-provider-agent
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default cluster-api-provider-agent .

#RUN go mod tidy
RUN go build -tags ${BUILD_TAGS} -a -o manager main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /
COPY --from=builder /opt/app-root/src/manager .

USER 65532:65532

ENTRYPOINT ["/manager"]

LABEL summary="multicluster-engine-cluster-api-provider-agent" \
      io.k8s.display-name="MCE Cluster API Provider Agent" \
      maintainer="['maintainers@okd.io']"
