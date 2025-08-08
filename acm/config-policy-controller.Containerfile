FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=config-policy-controller
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./config-policy-controller .

RUN make build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/config-policy-controller \
    USER_UID=1001 \
    USER_NAME=config-policy-controller

# install operator binary
COPY --from=builder /opt/app-root/src/build/_output/bin/config-policy-controller ${OPERATOR}

COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint", "controller"]

USER ${USER_UID}

# Make sure that these labels are correctly updated if your container is an operator!
LABEL io.k8s.display-name="config-policy-controller"
