FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicloud-manager
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicluster-engine/multicloud-operators-foundation multicluster-engine/multicloud-operators-foundation
COPY --chown=default .git .git

WORKDIR $HOME/multicluster-engine/multicloud-operators-foundation

RUN make build


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=10001 \
    USER_NAME=acm-foundation \
    REMOTE_SOURCE_DIR=/opt/app-root/src/multicluster-engine/multicloud-operators-foundation

COPY --from=builder $REMOTE_SOURCE_DIR/proxyserver /
COPY --from=builder $REMOTE_SOURCE_DIR/controller /
COPY --from=builder $REMOTE_SOURCE_DIR/webhook /
COPY --from=builder $REMOTE_SOURCE_DIR/agent /

USER ${USER_UID}

LABEL summary="multicloud-manager" \
      io.k8s.display-name="multicloud-manager" \
      maintainer="['maintainers@okd.io']" \
      description="multicloud-manager"
