FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/observatorium/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=observatorium
ENV COMPONENT_VERSION=${VERSION}
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/observatorium/app

RUN yum install -y make git ca-certificates
RUN source $REMOTE_SOURCES_DIR/observatorium/cachito.env && make observatorium

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

COPY --from=builder $REMOTE_SOURCES_DIR/observatorium/app/observatorium /bin/observatorium

LABEL com.redhat.component="observatorium-container" \
      name="rhacm2/observatorium-rhel9" \
      version="v2.13.3" \
      upstream-ref="0e616afb1694c01cfb18b4d39b1eb0834cdc5983" \
      upstream-url="git@github.com:stolostron/observatorium.git" \
      summary="observatorium" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="observatorium/observatorium" \
      io.k8s.description="Observatorium API" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="Observatorium API"

ENTRYPOINT ["/bin/observatorium"]