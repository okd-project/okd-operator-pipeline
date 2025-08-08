ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicloud-integrations
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicloud-integrations .

RUN make -f Makefile.prow build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/multicluster-integrations \
    USER_UID=1001 \
    USER_NAME=multicluster-integrations

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

# install operator binary
COPY --from=builder $REMOTE_SOURCE_DIR/build/_output/bin/gitopscluster /usr/local/bin/gitopscluster
COPY --from=builder $REMOTE_SOURCE_DIR/build/_output/bin/gitopssyncresc /usr/local/bin/gitopssyncresc
COPY --from=builder $REMOTE_SOURCE_DIR/build/_output/bin/multiclusterstatusaggregation /usr/local/bin/multiclusterstatusaggregation
COPY --from=builder $REMOTE_SOURCE_DIR/build/_output/bin/propagation /usr/local/bin/propagation
COPY --from=builder $REMOTE_SOURCE_DIR/build/_output/bin/gitopsaddon /usr/local/bin/gitopsaddon

COPY --from=builder $REMOTE_SOURCE_DIR/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL summary="multicloud-integrations" \
      io.k8s.display-name="multicloud-integrations" \
      io.k8s.description="multicloud-integrations" \
      maintainer="maintainers@okd.io" \
      description="multicloud-integrations"
