ARG CI_VERSION
ARG CI_REVISION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV COMPONENT_NAME=submariner-route-agent \
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
    echo CI_UPSTREAM_COMMIT="$COMPONENT_GIT_COMMIT" && \
    echo CI_UPSTREAM_VERSION="$CI_VERSION" && \
    go env

# build
RUN go build -mod=mod --ldflags "-s -w \
    -X github.com/submariner-io/submariner/pkg/versions.version=${COMPONENT_VERSION} \
    -X github.com/submariner-io/submariner/pkg/versions.gitCommitHash=${COMPONENT_GIT_COMMIT}" \
    -tags strictfipsruntime \
    -o bin/submariner-route-agent pkg/routeagent_driver/main.go

RUN go build -mod=mod --ldflags "-s -w \
    -X github.com/submariner-io/submariner/pkg/versions.version=${COMPONENT_VERSION} \
    -X github.com/submariner-io/submariner/pkg/versions.gitCommitHash=${COMPONENT_GIT_COMMIT}" \
    -tags strictfipsruntime \
    -o bin/await-node-ready pkg/await_node_ready/main.go

FROM quay.io/centos/centos:stream9-minimal

RUN microdnf -y update && \
    microdnf -y install centos-release-nfv-openvswitch && \
    microdnf -y install --nodocs iproute iptables ipset openvswitch2.17 shadow-utils procps-ng grep && \
    microdnf clean all

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

COPY --from=builder $REMOTE_SOURCE_DIR/bin/submariner-route-agent \
    $REMOTE_SOURCE_DIR/package/submariner-route-agent.sh \
    $REMOTE_SOURCE_DIR/package/await-node-ready.sh \
    $REMOTE_SOURCE_DIR/bin/await-node-ready \
    /usr/local/bin/

RUN chmod a+x /usr/local/bin/submariner-route-agent /usr/local/bin/submariner-route-agent.sh /usr/local/bin/await-node-ready.sh /usr/local/bin/await-node-ready

RUN mkdir /licenses

COPY --from=builder $REMOTE_SOURCE_DIR/LICENSE /licenses/

ENTRYPOINT ["/usr/local/bin/submariner-route-agent.sh"]

LABEL summary="submariner-route-agent" \
      io.k8s.display-name="submariner-route-agent" \
      io.k8s.description="submariner-route-agent" \
      maintainer="maintainers@okd.io" \
      description="submariner-route-agent"
