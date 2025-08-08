FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=klusterlet-addon-controller
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./klusterlet-addon-controller .

RUN go build -tags strictfipsruntime ./cmd/manager

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV IMAGE_MANIFEST_PATH=/
ENV OPERATOR=/usr/local/bin/klusterlet-addon-controller \
    USER_UID=10001 \
    USER_NAME=klusterlet-addon-controller

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

COPY --from=builder $REMOTE_SOURCE_DIR/deploy/crds deploy/crds
COPY --from=builder $REMOTE_SOURCE_DIR/manager ${OPERATOR}
COPY --from=builder $REMOTE_SOURCE_DIR/build/bin/entrypoint /usr/local/bin
COPY --from=builder $REMOTE_SOURCE_DIR/build/bin/user_setup /usr/local/bin

RUN  /usr/local/bin/user_setup

USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/entrypoint"]

LABEL summary="klusterlet-addon-controller" \
      io.k8s.display-name="klusterlet-addon-controller" \
      maintainer="['maintainers@okd.io']" \
      description="klusterlet-addon-controller"

