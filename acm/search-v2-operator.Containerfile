FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-search-v2-operator
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

# RUN source $CACHITO_ENV_FILE && make <project>
RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime -a -o manager main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

# COPY --from=builder $REMOTE_SOURCE_DIR/app/<content>

ENV USER_UID=1001 \
    USER_NAME=search-v2-operator

RUN microdnf update -y && microdnf clean all

# install operator binary
COPY --from=builder $REMOTE_SOURCE_DIR/app/manager .
USER ${USER_UID}

ENTRYPOINT ["/manager"]

LABEL com.redhat.component="acm-search-v2-operator-container" \
      name="rhacm2/acm-search-v2-rhel9" \
      version="v2.13.3" \
      summary="acm-search-v2-operator" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-search-v2-operator" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="acm-search-v2-operator"

#20240822