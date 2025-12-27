ARG BUILDVERSION
ARG BUILDVERSION_Y

FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder
ARG BUILDVERSION

# Copy source code
COPY go.mod .
COPY go.sum .
COPY vendor/ vendor/
COPY cmd/ cmd/
COPY pkg/ pkg/

ENV GOEXPERIMENT strictfipsruntime
RUN go build -tags strictfipsruntime -ldflags "-X 'main.BuildVersion=$BUILDVERSION' -X 'main.BuildDate=`date +%Y-%m-%d\ %H:%M`'" "./cmd/flowlogs-pipeline"

# final stage
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
ARG BUILDVERSION
ARG BUILDVERSION_Y

WORKDIR /
COPY --from=builder /opt/app-root/src/flowlogs-pipeline .
COPY LICENSE /licenses/

USER 65532:65532

ENTRYPOINT ["/flowlogs-pipeline"]

LABEL distribution-scope="public"
LABEL url="https://github.com/okd-project/okderators-catalog-index"
LABEL vendor="OKD Community"
LABEL release=$BUILDVERSION
LABEL io.k8s.display-name="Network Observability Flow-Logs Pipeline"
LABEL io.k8s.description="Network Observability Flow-Logs Pipeline"
LABEL summary="Network Observability Flow-Logs Pipeline"
LABEL maintainer="maintainers@okd.io"
LABEL io.openshift.tags="network-observability-flowlogs-pipeline"
LABEL description="Flow-Logs Pipeline is an observability tool that consumes logs from various inputs, transforms them and exports logs to Loki and metrics to Prometheus."
LABEL version=$BUILDVERSION
