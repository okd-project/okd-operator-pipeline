FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.prow.cached Dockerfile.prow.cached
RUN /dockerfile-drifter.sh build/Dockerfile.prow Dockerfile.prow.cached
COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh build/Dockerfile Dockerfile.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicloud-integrations
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && make -f Makefile.prow build

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf update -y && \
     microdnf clean all

ENV OPERATOR=/usr/local/bin/multicluster-integrations \
    USER_UID=1001 \
    USER_NAME=multicluster-integrations

# install operator binary
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/gitopscluster /usr/local/bin/gitopscluster
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/gitopssyncresc /usr/local/bin/gitopssyncresc
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/multiclusterstatusaggregation /usr/local/bin/multiclusterstatusaggregation
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/propagation /usr/local/bin/propagation
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/gitopsaddon /usr/local/bin/gitopsaddon

COPY --from=builder $REMOTE_SOURCE_DIR/app/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL com.redhat.component="multicloud-integrations-container" \
      name="rhacm2/multicloud-integrations-rhel9" \
      version="v2.13.3" \
      upstream-ref="fef54f2de2e10b97eef263b7e552efd4fb52cabc" \
      upstream-url="git@github.com:stolostron/multicloud-integrations.git" \
      summary="multicloud-integrations" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="multicloud-integrations" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="multicloud-integrations"

# 20250430
