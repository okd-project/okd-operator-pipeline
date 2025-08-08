FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=work
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ocm .

RUN CGO_ENABLED=1 GOFLAGS='-p=4' GO_BUILD_PACKAGES=./cmd/work make build --warn-undefined-variables


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=10001

COPY --from=builder /opt/app-root/src/work /

USER ${USER_UID}

LABEL summary="work" \
      io.k8s.display-name="work" \
      maintainer="['maintainers@okd.io']" \
      description="work"

