FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=cert-policy-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default cert-policy-controller .

RUN make build


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV COMPONENT=cert-policy-controller
ENV OPERATOR=/usr/local/bin/${COMPONENT} \
    USER_UID=1001 \
    USER_NAME=${COMPONENT}

# install operator binary
COPY --from=builder /opt/app-root/src/build/_output/bin/${COMPONENT} ${OPERATOR}
COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin

RUN  /usr/local/bin/user_setup

RUN microdnf -y update && \
    microdnf install shadow-utils procps -y && \
    microdnf clean all

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL summary="cert-policy-controller" \
      io.k8s.display-name="cert-policy-controller" \
      maintainer="['maintainers@okd.io']" \
      description="cert-policy-controller"
