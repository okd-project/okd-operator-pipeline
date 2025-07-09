FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh operators/endpointmetrics/Dockerfile Dockerfile.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=endpoint-monitoring-operator
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

RUN source $CACHITO_ENV_FILE && GOFLAGS="-p=4" go build -tags strictfipsruntime -a -installsuffix cgo -o build/_output/bin/endpoint-monitoring-operator operators/endpointmetrics/main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

ENV OPERATOR=/usr/local/bin/endpoint-monitoring-operator \
    USER_UID=1001 \
    USER_NAME=endpoint-monitoring-operator

RUN microdnf update -y && microdnf clean all

COPY --from=builder $REMOTE_SOURCE_DIR/app/operators/endpointmetrics/manifests /usr/local/manifests

COPY --from=builder $REMOTE_SOURCE_DIR/app/build/_output/bin/endpoint-monitoring-operator ${OPERATOR}

USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/endpoint-monitoring-operator"]

LABEL com.redhat.component="endpoint-monitoring-operator-container" \
      name="rhacm2/endpoint-monitoring-rhel9-operator" \
      version="v2.13.3" \
      upstream-ref="175c9f874d7beeeba3d2df0e3251a5ab6b2bf357" \
      upstream-url="git@github.com:stolostron/multicluster-observability-operator.git" \
      summary="endpoint-monitoring-operator" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="endpoint-monitoring-operator" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="endpoint-monitoring-operator"

# 20210204

