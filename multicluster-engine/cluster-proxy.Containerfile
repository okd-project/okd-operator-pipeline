FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=cluster-proxy
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default cluster-proxy .

RUN go build -tags strictfipsruntime -a -o agent cmd/addon-agent/main.go
RUN go build -tags strictfipsruntime -a -o manager cmd/addon-manager/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=10001

WORKDIR /
COPY --from=builder /opt/app-root/src/agent ./
COPY --from=builder /opt/app-root/src/manager ./
USER ${USER_UID}

LABEL summary="cluster-proxy" \
      io.k8s.display-name="cluster-proxy" \
      maintainer="['maintainers@okd.io']" \
      description="cluster-proxy"
