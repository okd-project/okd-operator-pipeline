FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-governance-policy-framework-addon
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default governance-policy-framework-addon .

RUN make build


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV COMPONENT=governance-policy-framework-addon \
    OPERATOR=/usr/local/bin/${COMPONENT} \
    USER_UID=1001 \
    USER_NAME=${COMPONENT}

# install operator binary
COPY --from=builder /opt/app-root/src/build/_output/bin/${COMPONENT} ${OPERATOR}

COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

RUN microdnf -y update && microdnf clean all

USER ${USER_UID}

# Make sure that these labels are correctly updated if your container is an operator!
LABEL summary="acm-governance-policy-framework-addon" \
      io.k8s.display-name="acm-governance-policy-framework-addon" \
      maintainer="['maintainers@okd.io']" \
      description="acm-governance-policy-framework-addon"

