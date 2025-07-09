FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-siteconfig
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

# Upstream command:
# RUN CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} GO111MODULE=on \
#  go build -mod=vendor -a -o build/siteconfig-manager cmd/main.go

RUN source $CACHITO_ENV_FILE && go build -tags strictfipsruntime -trimpath -o build/siteconfig-manager cmd/main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

COPY --from=builder $REMOTE_SOURCE_DIR/app/build/siteconfig-manager /usr/local/bin/siteconfig-manager

#COPY LICENSE /licenses/LICENSE

ENV USER_UID=1001
USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/siteconfig-manager"]

LABEL com.redhat.component="acm-siteconfig-container" \
      name="rhacm2/acm-siteconfig-rhel9" \
      version="v2.13.3" \
      summary="acm-siteconfig" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-siteconfig" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="acm-siteconfig"
