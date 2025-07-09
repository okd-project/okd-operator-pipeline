FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh build/Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-governance-policy-framework-addon
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && make build

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

ENV COMPONENT=governance-policy-framework-addon \
    OPERATOR=/usr/local/bin/${COMPONENT} \
    USER_UID=1001 \
    USER_NAME=${COMPONENT}

# install operator binary
COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/${COMPONENT} ${OPERATOR}

COPY --from=builder $REMOTE_SOURCE_DIR/app/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

RUN microdnf -y update && microdnf clean all

USER ${USER_UID}

# Make sure that these labels are correctly updated if your container is an operator!
LABEL com.redhat.component="acm-governance-policy-framework-addon-container" \
      name="rhacm2/acm-governance-policy-framework-addon-rhel9" \
      version="v2.13.3" \
      upstream-ref="ef9dc25a0ac50c5dfc875ae47e807b20163da1a6" \
      upstream-url="git@github.com:stolostron/governance-policy-framework-addon.git" \
      summary="acm-governance-policy-framework-addon" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-governance-policy-framework-addon" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="acm-governance-policy-framework-addon"

# 20210616

