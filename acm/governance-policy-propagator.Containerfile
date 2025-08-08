FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=governance-policy-propagator
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default governance-policy-propagator .

RUN make build


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV COMPONENT=governance-policy-propagator \
    OPERATOR=/usr/local/bin/${COMPONENT} \
    USER_UID=1001 \
    USER_NAME=${COMPONENT}

# install operator binary
COPY --from=builder /opt/app-root/src/build/_output/bin/${COMPONENT} ${OPERATOR}
COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL summary="governance-policy-propagator" \
      io.k8s.display-name="governance-policy-propagator" \
      maintainer="['maintainers@okd.io']" \
      description="governance-policy-propagator"
