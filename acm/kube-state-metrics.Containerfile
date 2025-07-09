FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/kube-state-metrics/app

COPY Dockerfile.cached Dockerfile.cached
COPY Dockerfile.prow.cached Dockerfile.prow.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile.prow Dockerfile.prow.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=kube-state-metrics
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/kube-state-metrics/app

RUN source $REMOTE_SOURCES_DIR/kube-state-metrics/cachito.env && go build -tags strictfipsruntime --installsuffix cgo

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf update -y && microdnf clean all

COPY --from=builder $REMOTE_SOURCES_DIR/kube-state-metrics/app/kube-state-metrics  /usr/bin/kube-state-metrics
USER nobody
ENTRYPOINT ["/usr/bin/kube-state-metrics"]

LABEL com.redhat.component="kube-state-metrics-container" \
      name="rhacm2/kube-state-metrics-rhel9" \
      version="v2.13.3" \
      upstream-ref="6b28ec0db2401240fbef16621c988318a80a6fdd" \
      upstream-url="git@github.com:stolostron/kube-state-metrics.git" \
      summary="kube-state-metrics" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="kube-state-metrics" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="kube-state-metrics"

# 20221024
