FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached
COPY Dockerfile.locust.cached Dockerfile.locust.cached
RUN /dockerfile-drifter.sh Dockerfile.locust Dockerfile.locust.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-search-indexer
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

# RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime -trimpath -o main main.go
RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime -trimpath -o main main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf -y update && microdnf clean all
RUN microdnf install ca-certificates vi --nodocs -y && microdnf clean all

COPY --from=builder $REMOTE_SOURCE_DIR/app/main /bin/main

ENV VCS_REF="$VCS_REF" \
    USER_UID=1001

EXPOSE 3010
USER ${USER_UID}
ENTRYPOINT ["/bin/main"]

LABEL com.redhat.component="acm-search-indexer-container" \
      name="rhacm2/acm-search-indexer-rhel9" \
      version="v2.13.3" \
      summary="acm-search-indexer" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-search-indexer" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="acm-search-indexer"

# 20240822
