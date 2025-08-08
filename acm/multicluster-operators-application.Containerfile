ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-operators-application
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicloud-operators-application .

RUN make build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/multicluster-operators-application \
    USER_UID=1001 \
    USER_NAME=multicluster-operators-application

RUN mkdir -p /usr/local/etc/application/crds

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

COPY --from=builder $REMOTE_SOURCE_DIR/deploy/crds/*.yaml /usr/local/etc/application/crds/
COPY --from=builder $REMOTE_SOURCE_DIR/build/_output/bin/multicluster-operators-application ${OPERATOR}
COPY --from=builder $REMOTE_SOURCE_DIR/build/bin /usr/local/bin

RUN /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL summary="multicluster-operators-application" \
      io.k8s.display-name="multicluster-operators-application" \
      io.k8s.description="multicluster-operators-application" \
      maintainer="maintainers@okd.io" \
      description="multicluster-operators-application"
