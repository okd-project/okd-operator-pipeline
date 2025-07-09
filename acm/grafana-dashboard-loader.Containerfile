FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh loaders/dashboards/Dockerfile Dockerfile.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=grafana-dashboard-loader
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

# RUN export GO111MODULE=on && go mod tidy

RUN source $CACHITO_ENV_FILE \
    && export GO111MODULE=on \
    && go build -tags strictfipsruntime -a -o grafana-dashboard-loader loaders/dashboards/cmd/main.go \
    && strip grafana-dashboard-loader

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

WORKDIR /

#COPY --from=builder /go/src/github.com/stolostron/grafana-dashboard-loader/grafana-dashboard-loader .
COPY --from=builder $REMOTE_SOURCE_DIR/app/grafana-dashboard-loader .

ENTRYPOINT ["/grafana-dashboard-loader"]

LABEL com.redhat.component="grafana-dashboard-loader-container" \
      name="rhacm2/grafana-dashboard-loader-rhel9" \
      version="v2.13.3" \
      upstream-ref="175c9f874d7beeeba3d2df0e3251a5ab6b2bf357" \
      upstream-url="git@github.com:stolostron/multicluster-observability-operator.git" \
      summary="grafana-dashboard-loader" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="grafana-dashboard-loader" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="grafana-dashboard-loader"

# 20220831
