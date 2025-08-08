FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-flightctl-api
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./flightctl/ .

RUN SOURCE_GIT_TAG=v0.5.1 \
    SOURCE_GIT_TREE_STATE=clean \
    SOURCE_GIT_COMMIT=76486ae1 \
    make build-api


FROM registry.access.redhat.com/ubi9/ubi:latest AS certs

RUN dnf update --nodocs -y && \
    dnf install ca-certificates tzdata --nodocs -y


FROM registry.access.redhat.com/ubi9-minimal:latest

WORKDIR /app

COPY --from=builder /opt/app-root/src/bin/flightctl-api .
COPY --from=certs /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/
COPY --from=certs /usr/share/zoneinfo /usr/share/zoneinfo

CMD ./flightctl-api


LABEL summary="acm-flightctl-api" \
      io.k8s.display-name="acm-flightctl-api" \
      maintainer="['maintainers@rokd.io']" \
      description="acm-flightctl-api"
