FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh build/Dockerfile Dockerfile.cached
COPY Dockerfile.prow.cached Dockerfile.prow.cached
RUN /dockerfile-drifter.sh build/Dockerfile.prow Dockerfile.prow.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-operators-application
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && make build

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

ENV OPERATOR=/usr/local/bin/multicluster-operators-application \
    USER_UID=1001 \
    USER_NAME=multicluster-operators-application

RUN mkdir -p /usr/local/etc/application/crds

COPY --from=builder $REMOTE_SOURCE_DIR/app/deploy/crds/*.yaml /usr/local/etc/application/crds/
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/multicluster-operators-application ${OPERATOR}
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/bin /usr/local/bin

RUN /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL com.redhat.component="multicluster-operators-application-container" \
      name="rhacm2/multicluster-operators-application-rhel9" \
      version="v2.13.3" \
      upstream-ref="8b0b7345150e1127eb345f2d8d4a7b6264e4019b" \
      upstream-url="git@github.com:stolostron/multicloud-operators-application.git" \
      summary="multicluster-operators-application" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="multicluster-operators-application" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="multicluster-operators-application"

# 20240822

