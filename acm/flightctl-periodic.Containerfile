FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/flightctl/app

COPY Containerfile.periodic.cached Containerfile.periodic.cached
RUN /dockerfile-drifter.sh Containerfile.periodic Containerfile.periodic.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-flightctl-periodic
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"
# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/flightctl/app

RUN source $REMOTE_SOURCES_DIR/flightctl/cachito.env && \
  SOURCE_GIT_TAG=v0.5.1 \
  SOURCE_GIT_TREE_STATE=clean \
  SOURCE_GIT_COMMIT=76486ae1 \
  make build-periodic



#@follow_tag(registry.redhat.io/ubi9/ubi:latest)
FROM registry.redhat.io/ubi9/ubi:9.6-1747219013 AS certs

RUN dnf update --nodocs -y && \
    dnf install ca-certificates tzdata --nodocs -y



#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

WORKDIR /app

COPY --from=builder $REMOTE_SOURCES_DIR/flightctl/app/bin/flightctl-periodic .
COPY --from=certs /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/

CMD ./flightctl-periodic


LABEL com.redhat.component="acm-flightctl-periodic-container" \
      name="rhacm2/acm-flightctl-periodic-rhel9" \
      version="v2.13.3" \
      upstream-ref="76486ae190a6d9eebfd54b93498ea43f8d298e39" \
      upstream-url="git@github.com:flightctl/flightctl.git" \
      summary="acm-flightctl-periodic" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-flightctl-periodic" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="acm-flightctl-periodic"

# 20220831
