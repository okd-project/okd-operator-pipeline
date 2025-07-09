FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-volsync-addon-controller
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime -a -o controller -ldflags "-X main.versionFromGit=${COMPONENT_VERSION} -X main.commitFromGit=08a20526d7e007227199240d7b18d247992716f1" main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

# Needs openssh in order to generate ssh keys
RUN microdnf -y --refresh update && \
    microdnf clean all

WORKDIR /
COPY --from=builder $REMOTE_SOURCE_DIR/app/controller .
# VolSync helm charts
COPY $REMOTE_SOURCE/app/helmcharts/ helmcharts/
# uid/gid: nobody/nobody
USER 65534:65534

ENV EMBEDDED_CHARTS_DIR=/helmcharts

ENTRYPOINT ["/controller"]

LABEL com.redhat.component="acm-volsync-addon-controller-container" \
      name="rhacm2/acm-volsync-addon-controller-rhel9" \
      version="v2.13.3" \
      upstream-ref="08a20526d7e007227199240d7b18d247992716f1" \
      upstream-url="git@github.com:stolostron/volsync-addon-controller.git" \
      summary="acm-volsync-addon-controller" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-volsync-addon-controller" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="acm-volsync-addon-controller"
