FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh build/Dockerfile Dockerfile.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=klusterlet-addon-controller
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime ./cmd/manager

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

ENV IMAGE_MANIFEST_PATH=/
ENV OPERATOR=/usr/local/bin/klusterlet-addon-controller \
    USER_UID=10001 \
    USER_NAME=klusterlet-addon-controller

COPY --from=builder $REMOTE_SOURCE_DIR/app/deploy/crds deploy/crds
COPY --from=builder $REMOTE_SOURCE_DIR/app/manager ${OPERATOR}
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/bin/entrypoint /usr/local/bin
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/bin/user_setup /usr/local/bin

RUN  /usr/local/bin/user_setup

USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/entrypoint"]

LABEL com.redhat.component="klusterlet-addon-controller-container" \
      name="rhacm2/klusterlet-addon-controller-rhel9" \
      version="v2.13.3" \
      upstream-ref="89b197e1f815a00e71f8fe34946d2a7456da2960" \
      upstream-url="git@github.com:stolostron/klusterlet-addon-controller.git" \
      summary="klusterlet-addon-controller" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="klusterlet-addon-controller" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="klusterlet-addon-controller"

# 20240822

