FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/observatorium-operator/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV COMPONENT_NAME=observatorium-operator
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR

#WORKDIR $REMOTE_SOURCES_DIR/observatorium-operator/app
#RUN source $REMOTE_SOURCES_DIR/observatorium-operator/cachito.env && GO111MODULE="on" go build -tags strictfipsruntime github.com/brancz/locutus

WORKDIR $REMOTE_SOURCES_DIR/locutus/app
RUN source $REMOTE_SOURCES_DIR/locutus/cachito.env && GO111MODULE="on" go build -tags strictfipsruntime

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9/ubi:latest)
FROM registry.redhat.io/ubi9/ubi:9.6-1745489786

RUN dnf -y update && dnf clean all

WORKDIR /
#COPY --from=builder $REMOTE_SOURCES_DIR/observatorium-operator/app/locutus /
COPY --from=builder $REMOTE_SOURCES_DIR/locutus/app/locutus /locutus
COPY --from=builder $REMOTE_SOURCES_DIR/observatorium-operator/app/jsonnet /
COPY --from=builder $REMOTE_SOURCES_DIR/observatorium-operator/app/jsonnet/vendor/ /vendor/
COPY --from=builder $REMOTE_SOURCES_DIR/observatorium-operator/app/jsonnet/vendor/github.com/observatorium/observatorium/configuration/components/ /components/
RUN chgrp -R 0 /vendor && chmod -R g=u /vendor
RUN chgrp -R 0 /components && chmod -R g=u /components

ENTRYPOINT ["/locutus", "--renderer=jsonnet", "--renderer.jsonnet.entrypoint=main.jsonnet", "--trigger=resource", "--trigger.resource.config=config.yaml"]

LABEL com.redhat.component="observatorium-operator-container" \
      name="rhacm2/observatorium-rhel9-operator" \
      version="v2.13.3" \
      upstream-ref="141e4fbf22cd1f51a9e38ea3464feb84ed796681" \
      upstream-url="git@github.com:stolostron/observatorium-operator.git" \
      summary="observatorium-operator" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="observatorium-operator" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="observatorium-operator"
