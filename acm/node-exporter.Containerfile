FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/node-exporter/app

COPY Dockerfile.cached Dockerfile.cached
COPY Dockerfile.ocp.cached Dockerfile.ocp.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile.ocp Dockerfile.ocp.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=node-exporter
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/node-exporter/app

RUN source $REMOTE_SOURCES_DIR/node-exporter/cachito.env && go build -tags strictfipsruntime --installsuffix cgo

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

COPY --from=builder --from=builder $REMOTE_SOURCES_DIR/node-exporter/app/node_exporter /bin/node_exporter

RUN microdnf update -y && microdnf install -y virt-what && microdnf clean all && rm -rf /var/cache/*

EXPOSE      9100
USER        nobody
ENTRYPOINT  [ "/bin/node_exporter" ]

LABEL com.redhat.component="node-exporter-container" \
      name="rhacm2/node-exporter-rhel9" \
      version="v2.13.3" \
      upstream-ref="dec03729cacbfec0d1a9e6a2bf421d8bf78fae9f" \
      upstream-url="git@github.com:stolostron/node-exporter.git" \
      summary="node-exporter" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="node-exporter" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="node-exporter"
