FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached
COPY Dockerfile.prow.cached Dockerfile.prow.cached
RUN /dockerfile-drifter.sh build/Dockerfile.prow Dockerfile.prow.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multiclusterhub-operator
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime -o multiclusterhub-operator main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

WORKDIR /
COPY --from=builder $REMOTE_SOURCE_DIR/app/multiclusterhub-operator /usr/local/bin/multiclusterhub-operator
COPY --from=builder $REMOTE_SOURCE_DIR/app/pkg/templates/ /usr/local/templates/

USER 65532:65532

ENTRYPOINT ["multiclusterhub-operator"]

LABEL com.redhat.component="multiclusterhub-operator-container" \
      name="rhacm2/multiclusterhub-rhel9" \
      version="v2.13.3" \
      upstream-ref="603fbf1c1a0423f8f642d6798d4a00b55f9edbe8" \
      upstream-url="git@github.com:stolostron/multiclusterhub-operator.git" \
      summary="multiclusterhub-operator" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="multiclusterhub-operator" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="Installer operator for Red Hat Advanced Cluster Management"

# 20220831
