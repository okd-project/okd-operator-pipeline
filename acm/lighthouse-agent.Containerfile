FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.lighthouse-agent.cached Dockerfile.lighthouse-agent.cached
RUN /dockerfile-drifter.sh package/Dockerfile.lighthouse-agent Dockerfile.lighthouse-agent.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.9-202506111225.g6c23478.el9 AS builder

# Dummy copy command to force execution of drifter
COPY --from=drifter $REMOTE_SOURCE_DIR/app/Dockerfile.lighthouse-agent.cached /tmp/Dockerfile.lighthouse-agent.cached

ENV COMPONENT_NAME=lighthouse-agent \
COMPONENT_VERSION=v0.17.6 \
COMPONENT_TAG_EXTENSION=" " \
GO111MODULE=on \
GOFLAGS="-p=4" \
GOCACHE=$REMOTE_SOURCE_DIR/deps/gomod \
GOMODCACHE=$REMOTE_SOURCE_DIR/deps/gomod/pkg/mod \
GOPATH=$REMOTE_SOURCE_DIR/deps/gomod

# Cachito
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR

WORKDIR $REMOTE_SOURCE_DIR/app

# DEBUG
RUN echo CI_CONTAINER_VERSION="v0.17.6" && \
    echo CI_VERSION="0.17.6" && \
    echo CI_UPSTREAM_COMMIT="8f46a66423c6a4779b4c5b56eb2dc8992f135800" && \
    echo CI_UPSTREAM_VERSION="0.17.6" && \
    go env

# build
RUN go build --ldflags "-X main.version=${COMPONENT_VERSION} -s -w" -o bin/lighthouse-agent pkg/agent/main.go
#----------------------------------------#


#@follow_tag(registry.redhat.io/rhel9-2-els/rhel-minimal:9.2)
FROM registry.redhat.io/rhel9-2-els/rhel-minimal:9.2-262

RUN microdnf -y update && \
    microdnf -y install --nodocs shadow-utils && \
    microdnf clean all

RUN adduser -r -l -u 1001010000 lighthouse

COPY --from=builder $REMOTE_SOURCE_DIR/app/bin/lighthouse-agent /usr/local/bin/

RUN chown lighthouse:lighthouse /usr/local/bin/lighthouse-agent && \
    chmod a+x /usr/local/bin/lighthouse-agent

RUN mkdir /licenses

COPY --from=builder $REMOTE_SOURCE_DIR/app/LICENSE /licenses/

USER 1001010000

ENTRYPOINT ["/usr/local/bin/lighthouse-agent", "-alsologtostderr"]

LABEL com.redhat.component="lighthouse-agent-container" \
      summary="lighthouse-agent" \
      io.k8s.display-name="lighthouse-agent" \
      io.k8s.description="lighthouse-agent"