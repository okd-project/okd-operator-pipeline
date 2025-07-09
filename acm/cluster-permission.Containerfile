FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-cluster-permission
ENV COMPONENT_VERSION=2.13.3
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


LABEL com.redhat.component="acm-cluster-permission-container" \
      name="rhacm2/acm-cluster-permission-rhel9" \
      version="v2.13.3" \
      upstream-ref="a1dca594df8eea1710a6e343856edb1383fba825" \
      upstream-url="git@github.com:stolostron/cluster-permission.git" \
      summary="cluster-permission" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-cluster-permission" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="cluster-permission"
