ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV COMPONENT_NAME=lighthouse-coredns \
COMPONENT_VERSION=$VERSION \
COMPONENT_TAG_EXTENSION=" " \
GO111MODULE=on \
GOFLAGS="-p=4" \
GOCACHE=$HOME/gomod \
GOMODCACHE=$HOME/gomod/pkg/mod \
GOPATH=$HOME/gomod \
GOEXPERIMENT=strictfipsruntime \
BUILD_TAGS="strictfipsruntime"

COPY --chown=default lighthouse .

# DEBUG
RUN echo CI_CONTAINER_VERSION="$VERSION" && \
    echo CI_VERSION="$VERSION" && \
    echo CI_UPSTREAM_COMMIT="20be141120717730a92230d23da07544830c1487" && \
    echo CI_UPSTREAM_VERSION="$VERSION" && \
    go env

# build
RUN cd coredns && go build --ldflags "-X main.version=${COMPONENT_VERSION} -s -w" -tags strictfipsruntime -o ../bin/lighthouse-coredns .
#----------------------------------------#

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && \
    microdnf -y install --nodocs shadow-utils && \
    microdnf clean all

COPY --from=builder /opt/app-root/src/bin/lighthouse-coredns /usr/local/bin/

RUN chmod a+x /usr/local/bin/lighthouse-coredns

# linux capability for enabling port 53
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/lighthouse-coredns

RUN mkdir /licenses

COPY --from=builder /opt/app-root/src/LICENSE /licenses/

ENTRYPOINT ["/usr/local/bin/lighthouse-coredns"]

LABEL summary="lighthouse-coredns" \
      io.k8s.display-name="lighthouse-coredns" \
      io.k8s.description="lighthouse-coredns" \
      maintainer="maintainers@okd.io" \
      description="lighthouse-coredns"
