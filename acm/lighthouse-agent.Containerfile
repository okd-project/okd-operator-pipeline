ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV COMPONENT_NAME=lighthouse-agent \
COMPONENT_VERSION=$VERSION \
COMPONENT_TAG_EXTENSION=" " \
GO111MODULE=on \
GOFLAGS="-p=4" \
GOCACHE=$HOME/gomod \
GOMODCACHE=$HOME/gomod/pkg/mod \
GOPATH=$HOME/gomod

COPY --chown=default lighthouse .

# DEBUG
RUN echo CI_CONTAINER_VERSION="$VERSION" && \
    echo CI_VERSION="$VERSION" && \
    echo CI_UPSTREAM_COMMIT="$REVISION" && \
    echo CI_UPSTREAM_VERSION="$VERSION" && \
    go env

# build
RUN go build --ldflags "-X main.version=${COMPONENT_VERSION} -s -w" -o bin/lighthouse-agent pkg/agent/main.go
#----------------------------------------#

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && \
    microdnf -y install --nodocs shadow-utils && \
    microdnf clean all

COPY --from=builder /opt/app-root/src/bin/lighthouse-agent /usr/local/bin/

RUN chmod a+x /usr/local/bin/lighthouse-agent

RUN mkdir /licenses

COPY --from=builder /opt/app-root/src/LICENSE /licenses/

ENTRYPOINT ["/usr/local/bin/lighthouse-agent", "-alsologtostderr"]

LABEL summary="lighthouse-agent" \
      io.k8s.display-name="lighthouse-agent" \
      io.k8s.description="lighthouse-agent" \
      maintainer="maintainers@okd.io" \
      description="lighthouse-agent"
