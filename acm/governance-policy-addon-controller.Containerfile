FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-governance-policy-addon-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default governance-policy-addon-controller .

RUN GOFLAGS="-p=4" GOTAGS=${BUILD_TAGS} make build


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV COMPONENT=governance-policy-addon-controller
ENV OPERATOR=/usr/local/bin/${COMPONENT} \
    USER_UID=1001 \
    USER_NAME=${COMPONENT}

COPY --from=builder /opt/app-root/src/build/_output/bin/${COMPONENT} ${OPERATOR}
COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

RUN microdnf -y update && \
    microdnf clean all

USER ${USER_UID}

LABEL summary="acm-governance-policy-addon-controller" \
      io.k8s.display-name="acm-governance-policy-addon-controller" \
      maintainer="['maintainers@okd.io']" \
      description="acm-governance-policy-addon-controller"
