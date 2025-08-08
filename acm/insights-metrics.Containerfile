FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=insights-metrics
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./insights-metrics .

RUN go build -tags strictfipsruntime -trimpath -o insights-metrics main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf install ca-certificates vi --nodocs -y &&\
    mkdir /licenses &&\
    microdnf clean all

ENV USER_UID=1001

COPY --from=builder /opt/app-root/src/insights-metrics /bin

EXPOSE 3031
USER ${USER_UID}
ENTRYPOINT ["/bin/insights-metrics"]


LABEL summary="insights-metrics" \
      io.k8s.display-name="insights-metrics" \
      maintainer="['maintainers@okd.io']" \
      description="insights-metrics"

# 20221024
