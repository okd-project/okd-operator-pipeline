FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-multicluster-observability-addon
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

#RUN source $CACHITO_ENV_FILE && GOFLAGS="-p=4" go mod tidy
RUN source $CACHITO_ENV_FILE && GOFLAGS="-p=4" go build -tags strictfipsruntime -a -o multicluster-observability-addon main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf -y update && microdnf clean all

COPY --from=builder $REMOTE_SOURCE_DIR/app/multicluster-observability-addon /usr/local/bin/multicluster-observability-addon

ENTRYPOINT ["/usr/local/bin/multicluster-observability-addon"]

USER ${USER_UID}


LABEL com.redhat.component="acm-multicluster-observability-addon-container" \
      name="rhacm2/acm-multicluster-observability-addon-rhel9" \
      version="v2.13.3" \
      upstream-ref="08eab090f70afa27dad88f4926502ec47d9b8e39" \
      upstream-url="git@github.com:stolostron/multicluster-observability-addon.git" \
      summary="cluster-permission" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-multicluster-observability-addon" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="cluster-permission"
