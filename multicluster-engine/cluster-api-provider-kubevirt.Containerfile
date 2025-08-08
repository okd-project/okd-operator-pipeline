FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-cluster-api-provider-kubevirt
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default cluster-api-provider-kubevirt .

RUN go build -tags ${BUILD_TAGS} -a -o manager .


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /
COPY --from=builder /opt/app-root/src/manager .
# Use uid of nonroot user (65532) because kubernetes expects numeric user when applying pod security policies
USER 65532
ENTRYPOINT ["/manager"]

LABEL summary="multicluster-engine-cluster-api-provider-kubevirt" \
      io.k8s.display-name="MCE Cluster API Provider KubeVirt" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-cluster-api-provider-kubevirt"
