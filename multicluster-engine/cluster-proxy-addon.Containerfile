FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=cluster-proxy-addon
ENV COMPONENT_VERSION=${CI_VERSION}
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default cluster-proxy-addon .

RUN make build-all

FROM registry.access.redhat.com/ubi9-minimal:9.6-1747218906

ENV USER_UID=10001

COPY --from=builder /opt/app-root/src/cluster-proxy /
COPY --from=builder /opt/app-root/src/proxy-agent /
COPY --from=builder /opt/app-root/src/proxy-server /

RUN microdnf -y update && microdnf clean all

USER ${USER_UID}

LABEL summary="cluster-proxy-addon" \
      io.k8s.display-name="cluster-proxy-addon" \
      io.k8s.description="cluster-proxy-addon" \
      maintainer="['maintainers@okd.io']" \
      description="cluster-proxy-addon"
