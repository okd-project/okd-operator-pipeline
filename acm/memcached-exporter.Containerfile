FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/memcached_exporter/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=memcached_exporter
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

### Build a custom binary of promu 0.15 ###
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/promu/app

# KEY CHANGE - Hack three lines from the promu build.go to remove -static flag
RUN sed -i -e '180,182d' $REMOTE_SOURCES_DIR/promu/app/cmd/build.go
RUN source $REMOTE_SOURCES_DIR/promu/cachito.env && go build -tags strictfipsruntime -o /usr/local/bin github.com/prometheus/promu

### Build memcached_exporter using the custom promu binary ###
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/memcached_exporter/app

#RUN microdnf install -y prometheus-promu
ENV BUILD_PROMU=false
RUN source $REMOTE_SOURCES_DIR/memcached_exporter/cachito.env && promu build --cgo

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

COPY --from=builder $REMOTE_SOURCES_DIR/memcached_exporter/app/memcached_exporter /bin/memcached_exporter

USER       nobody
ENTRYPOINT ["/bin/memcached_exporter"]
EXPOSE     9150


LABEL com.redhat.component="memcached-exporter-container" \
      name="rhacm2/memcached-exporter-rhel9" \
      version="v2.13.3" \
      upstream-ref="0671fbb007536cbbab14a91f64690e5d24b46e59" \
      upstream-url="git@github.com:stolostron/memcached_exporter.git" \
      summary="memcached-exporter" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="memcached-exporter" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="memcached-exporter"