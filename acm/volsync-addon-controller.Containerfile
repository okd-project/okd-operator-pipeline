ARG VERSION
ARG REVISION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-volsync-addon-controller
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default volsync-addon-controller .

RUN go build -tags strictfipsruntime -a -o controller \
    -ldflags "-X main.versionFromGit=${COMPONENT_VERSION} -X main.commitFromGit=${REVISION}" main.go

FROM registry.access.redhat.com/ubi9-minimal:9.6-1747218906

RUN microdnf -y --refresh update && \
    microdnf clean all

WORKDIR /
COPY --from=builder /opt/app-root/src/controller .
COPY volsync-addon-controller/helmcharts/ helmcharts/
USER 65534:65534

ENV EMBEDDED_CHARTS_DIR=/helmcharts

ENTRYPOINT ["/controller"]

LABEL summary="acm-volsync-addon-controller" \
      io.k8s.display-name="acm-volsync-addon-controller" \
      io.k8s.description="acm-volsync-addon-controller" \
      maintainer="maintainers@okd.io" \
      description="acm-volsync-addon-controller"
