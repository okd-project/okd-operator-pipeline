# To test this locally...
# In the directory containing this file, clone the Lighthouse project
# as app:
#     git clone https://github.com/submariner-io/lighthouse app
# Populate vendor:
#     (cd app && go mod vendor)
# Build the container images:
#     docker build . -f Dockerfile.in
# For a full build this needs RHEL entitlements, but you'll be able to
# at least verify the Go build and examine the resulting artifact:
# from the build log, get the container id just before the FROM step
# involving ubi-minimal; then
#     docker run -it --rm <imageid>
# will give you a shell with access to the Lighthouse binaries that
# were just built.

FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.lighthouse-coredns.cached Dockerfile.lighthouse-coredns.cached
RUN /dockerfile-drifter.sh package/Dockerfile.lighthouse-coredns Dockerfile.lighthouse-coredns.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

# Dummy copy command to force execution of drifter
COPY --from=drifter $REMOTE_SOURCE_DIR/app/Dockerfile.lighthouse-coredns.cached /tmp/Dockerfile.lighthouse-coredns.cached

ENV COMPONENT_NAME=lighthouse-coredns \
COMPONENT_VERSION=v0.20.1 \
COMPONENT_TAG_EXTENSION=" " \
GO111MODULE=on \
GOFLAGS="-p=4" \
GOCACHE=$REMOTE_SOURCE_DIR/deps/gomod \
GOMODCACHE=$REMOTE_SOURCE_DIR/deps/gomod/pkg/mod \
GOPATH=$REMOTE_SOURCE_DIR/deps/gomod \
GOEXPERIMENT=strictfipsruntime \
BUILD_TAGS="strictfipsruntime"

# Cachito
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR

WORKDIR $REMOTE_SOURCE_DIR/app

# DEBUG
RUN echo CI_CONTAINER_VERSION="v0.20.1" && \
    echo CI_VERSION="0.20.1" && \
    echo CI_UPSTREAM_COMMIT="20be141120717730a92230d23da07544830c1487" && \
    echo CI_UPSTREAM_VERSION="0.20.1" && \
    go env

# build
RUN cd coredns && source $CACHITO_ENV_FILE && go build --ldflags "-X main.version=${COMPONENT_VERSION} -s -w" -tags strictfipsruntime -o ../bin/lighthouse-coredns .
#----------------------------------------#


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf -y update && \
    microdnf -y install --nodocs shadow-utils && \
    microdnf clean all

RUN adduser -r -l -u 1001010000 lighthouse

COPY --from=builder $REMOTE_SOURCE_DIR/app/bin/lighthouse-coredns /usr/local/bin/

RUN chown lighthouse:lighthouse /usr/local/bin/lighthouse-coredns && \
    chmod a+x /usr/local/bin/lighthouse-coredns

# linux capability for enabling port 53
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/lighthouse-coredns

RUN mkdir /licenses

COPY --from=builder $REMOTE_SOURCE_DIR/app/LICENSE /licenses/

USER 1001010000

EXPOSE 53 53/udp

ENTRYPOINT ["/usr/local/bin/lighthouse-coredns"]

LABEL com.redhat.component="lighthouse-coredns-container" \
      name="rhacm2/lighthouse-coredns-rhel9" \
      version="v0.20.1" \
      com.github.url="https://github.com/submariner-io/lighthouse.git" \
      com.github.commit="20be141120717730a92230d23da07544830c1487" \
      summary="lighthouse-coredns" \
      io.openshift.expose-services="53/udp:dns" \
      io.openshift.tags="submariner,lighthouse-coredns,rhel9" \
      io.openshift.wants="lighthouse-agent" \
      io.openshift.non-scalable="false" \
      io.k8s.display-name="lighthouse-coredns" \
      io.k8s.description="lighthouse-coredns" \
      maintainer="['multi-cluster-networking@redhat.com']" \
      description="lighthouse-coredns"
