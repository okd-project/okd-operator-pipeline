ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=node-exporter
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default node-exporter .

RUN go build -tags strictfipsruntime --installsuffix cgo


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/node_exporter /bin/node_exporter

RUN microdnf update -y && microdnf install -y virt-what && microdnf clean all && rm -rf /var/cache/*

EXPOSE      9100
USER        nobody
ENTRYPOINT  [ "/bin/node_exporter" ]

LABEL summary="node-exporter" \
      io.k8s.display-name="node-exporter" \
      io.k8s.description="node-exporter" \
      maintainer="maintainers@okd.io" \
      description="node-exporter"
