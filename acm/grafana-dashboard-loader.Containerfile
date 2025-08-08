FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=grafana-dashboard-loader
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicluster-observability-operator .

# RUN export GO111MODULE=on && go mod tidy

RUN export GO111MODULE=on \
    && go build -tags strictfipsruntime -a -o grafana-dashboard-loader loaders/dashboards/cmd/main.go \
    && strip grafana-dashboard-loader


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /

COPY --from=builder /opt/app-root/src/grafana-dashboard-loader .

ENTRYPOINT ["/grafana-dashboard-loader"]

LABEL summary="grafana-dashboard-loader" \
      io.k8s.display-name="grafana-dashboard-loader" \
      maintainer="['maintainers@okd.io']" \
      description="grafana-dashboard-loader"

# 20220831
