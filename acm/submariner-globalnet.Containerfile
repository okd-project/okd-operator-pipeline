# To test this locally...
# In the directory containing this file, clone the Submariner project
# as app:
#     git clone https://github.com/submariner-io/submariner app
# Populate vendor:
#     (cd app && go mod vendor)
# Build the container images:
#     docker build . -f Dockerfile.in
# For a full build this needs RHEL entitlements, but you'll be able to
# at least verify the Go build and examine the resulting artifact:
# from the build log, get the container id just before the FROM step
# involving ubi-minimal; then
#     docker run -it --rm <imageid>
# will give you a shell with access to the Submariner binaries that
# were just built.

FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.submariner-globalnet.cached Dockerfile.submariner-globalnet.cached
RUN /dockerfile-drifter.sh package/Dockerfile.submariner-globalnet Dockerfile.submariner-globalnet.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

# Dummy copy command to force execution of drifter
COPY --from=drifter $REMOTE_SOURCE_DIR/app/Dockerfile.submariner-globalnet.cached /tmp/Dockerfile.submariner-globalnet.cached

ENV COMPONENT_NAME=submariner-globalnet \
COMPONENT_VERSION=v0.20.1 \
COMPONENT_GIT_COMMIT=a1fabe7102a758f799a6b7f77ae64dd2ff0e635e \
COMPONENT_TAG_EXTENSION=" " \
GO111MODULE=on \
GOFLAGS="-mod=vendor -p=4" \
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
    echo CI_UPSTREAM_COMMIT="a1fabe7102a758f799a6b7f77ae64dd2ff0e635e" && \
    echo CI_UPSTREAM_VERSION="0.20.1" && \
    go env

# build
RUN go build --ldflags "-s -w \
    -X github.com/submariner-io/submariner/pkg/versions.version=${COMPONENT_VERSION} \
    -X github.com/submariner-io/submariner/pkg/versions.gitCommitHash=${COMPONENT_GIT_COMMIT}" \
    -tags strictfipsruntime \
    -o bin/submariner-globalnet pkg/globalnet/main.go

#-----------------------------------------------------------------------------------------------#


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf -y update && \
    microdnf -y install --nodocs iproute iptables ipset shadow-utils grep && \
    microdnf clean all

RUN adduser -r -l -u 1001010000 submariner

COPY --from=builder $REMOTE_SOURCE_DIR/app/bin/submariner-globalnet $REMOTE_SOURCE_DIR/app/package/submariner-globalnet.sh /usr/local/bin/

RUN chown submariner:submariner /usr/local/bin/submariner-globalnet /usr/local/bin/submariner-globalnet.sh && \
    chmod a+x /usr/local/bin/submariner-globalnet /usr/local/bin/submariner-globalnet.sh

RUN mkdir /licenses

COPY --from=builder $REMOTE_SOURCE_DIR/app/LICENSE /licenses/

# TODO: submariner-globalnet.sh and some go modules require to be run as superuser
#USER 1001010000

ENTRYPOINT ["/usr/local/bin/submariner-globalnet.sh"]

LABEL com.redhat.component="submariner-globalnet-container" \
      name="rhacm2/submariner-globalnet-rhel9" \
      version="v0.20.1" \
      com.github.url="https://github.com/submariner-io/submariner.git" \
      com.github.commit="a1fabe7102a758f799a6b7f77ae64dd2ff0e635e" \
      summary="submariner-globalnet" \
      io.openshift.expose-services="" \
      io.openshift.tags="submariner,submariner-globalnet,rhel9" \
      io.openshift.wants="submariner-gateway,submariner-route-agent" \
      io.openshift.non-scalable="true" \
      io.k8s.display-name="submariner-globalnet" \
      io.k8s.description="submariner-globalnet" \
      maintainer="['multi-cluster-networking@redhat.com']" \
      description="submariner-globalnet"
