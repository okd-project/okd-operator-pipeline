FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh proxy/Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=rbac-query-proxy
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GO111MODULE=on
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime -a -installsuffix cgo -v -o main proxy/cmd/main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

WORKDIR /
COPY --from=builder $REMOTE_SOURCE_DIR/app/main rbac-query-proxy
EXPOSE 3002
ENTRYPOINT ["/rbac-query-proxy"]

LABEL com.redhat.component="rbac-query-proxy-container" \
      name="rhacm2/rbac-query-proxy-rhel9" \
      version="v2.13.3" \
      upstream-ref="175c9f874d7beeeba3d2df0e3251a5ab6b2bf357" \
      upstream-url="git@github.com:stolostron/multicluster-observability-operator.git" \
      summary="rbac-query-proxy" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="rbac-query-proxy" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="rbac-query-proxy"

# 20220831
