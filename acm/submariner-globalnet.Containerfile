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

ARG CI_VERSION
ARG CI_REVISION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV COMPONENT_NAME=submariner-globalnet \
COMPONENT_VERSION=$CI_VERSION \
COMPONENT_GIT_COMMIT=$CI_REVISION \
COMPONENT_TAG_EXTENSION=" " \
GO111MODULE=on \
GOFLAGS="-mod=vendor -p=4" \
GOCACHE=$HOME/gomod \
GOMODCACHE=$HOME/gomod/pkg/mod \
GOPATH=$HOME/gomod \
GOEXPERIMENT=strictfipsruntime \
BUILD_TAGS="strictfipsruntime"

COPY --chown=default submariner .

# DEBUG
RUN echo CI_CONTAINER_VERSION="$CI_VERSION" && \
    echo CI_VERSION="$CI_VERSION" && \
    echo CI_UPSTREAM_COMMIT="$CI_REVISION" && \
    echo CI_UPSTREAM_VERSION="$CI_VERSION" && \
    go env

# build
RUN go build -mod=mod --ldflags "-s -w \
    -X github.com/submariner-io/submariner/pkg/versions.version=${COMPONENT_VERSION} \
    -X github.com/submariner-io/submariner/pkg/versions.gitCommitHash=${COMPONENT_GIT_COMMIT}" \
    -tags strictfipsruntime \
    -o bin/submariner-globalnet pkg/globalnet/main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && \
    microdnf -y install --nodocs iproute iptables ipset shadow-utils grep && \
    microdnf clean all

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

COPY --from=builder $REMOTE_SOURCE_DIR/bin/submariner-globalnet $REMOTE_SOURCE_DIR/package/submariner-globalnet.sh /usr/local/bin/

RUN chmod a+x /usr/local/bin/submariner-globalnet /usr/local/bin/submariner-globalnet.sh

RUN mkdir /licenses

COPY --from=builder $REMOTE_SOURCE_DIR/LICENSE /licenses/

ENTRYPOINT ["/usr/local/bin/submariner-globalnet.sh"]

LABEL summary="submariner-globalnet" \
      io.k8s.display-name="submariner-globalnet" \
      io.k8s.description="submariner-globalnet" \
      maintainer="maintainers@okd.io" \
      description="submariner-globalnet"
