FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=submariner-addon
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default submariner-addon .

ENV GO_PACKAGE github.com/stolostron/submariner-addon
ENV GO_LD_EXTRAFLAGS -X github.com/stolostron/submariner-addon/pkg/hub/submarinerbrokerinfo.catalogSource="redhat-operators"

RUN go mod vendor
RUN make build --warn-undefined-variables


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=10001

COPY --from=builder /opt/app-root/src/submariner /

USER ${USER_UID}

# Make sure that these labels are correctly updated if your container is an operator!
LABEL summary="submariner-addon" \
      io.k8s.display-name="submariner-addon" \
      maintainer="['maintainers@okd.io']" \
      description="submariner-addon"
