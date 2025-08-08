FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION
ARG CI_TAG

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=registration-operator
ENV COMPONENT_VERSION=$CI_VERSION
ENV SOURCE_GIT_TAG=$CI_TAG
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ocm .

RUN CGO_ENABLED=1 GOFLAGS='-p=4' GO_BUILD_PACKAGES=./cmd/registration-operator make build --warn-undefined-variables


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=10001

COPY --from=builder /opt/app-root/src/registration-operator /

USER ${USER_UID}

LABEL summary="registration-operator" \
      io.k8s.display-name="registration-operator" \
      maintainer="['maintainers@okd.io']" \
      description="registration-operator"
