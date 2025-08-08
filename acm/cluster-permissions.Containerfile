FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-cluster-permission
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./cluster-permission .

RUN make -f Makefile build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && microdnf clean all

ENV OPERATOR=/usr/local/bin/cluster-permission \
    USER_UID=1001 \
    USER_NAME=cluster-permission

# install operator binary
COPY --from=builder /opt/app-root/src/bin/cluster-permission /usr/local/bin/cluster-permission

COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin

RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}


LABEL summary="cluster-permission" \
      io.k8s.display-name="acm-cluster-permission" \
      maintainer="['maintainers@okd.io']" \
      description="cluster-permission"
