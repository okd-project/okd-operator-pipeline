FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-flightctl-worker
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default flightctl .

RUN SOURCE_GIT_TAG=v0.5.1 \
    SOURCE_GIT_TREE_STATE=clean \
    SOURCE_GIT_COMMIT=76486ae1 \
    make build-worker


FROM registry.access.redhat.com/ubi9/ubi:latest AS certs

RUN dnf update --nodocs -y && \
    dnf install ca-certificates tzdata --nodocs -y


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /app

COPY --from=builder /opt/app-root/src/bin/flightctl-worker .
COPY --from=certs /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/

CMD ./flightctl-worker

LABEL summary="acm-flightctl-worker" \
      io.k8s.display-name="acm-flightctl-worker" \
      maintainer="['maintainers@okd.io']" \
      description="acm-flightctl-worker"
