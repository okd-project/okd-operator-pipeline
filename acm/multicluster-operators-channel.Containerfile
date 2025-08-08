FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-operators-channel
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicloud-operators-channel .

RUN make build


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/multicluster-operators-channel \
    USER_UID=1001 \
    USER_NAME=multicluster-operators-channel

COPY --from=builder /opt/app-root/src/build/_output/bin/multicluster-operators-channel ${OPERATOR}
COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL summary="multicluster-operators-channel" \
      io.k8s.display-name="multicluster-operators-channel" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-operators-channel"
