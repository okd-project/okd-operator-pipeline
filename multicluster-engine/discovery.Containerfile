FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=discovery-operator
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default discovery .

RUN go build -tags strictfipsruntime -a -o manager main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /

# install operator binary
COPY --from=builder /opt/app-root/src/manager .

ENTRYPOINT ["/manager"]

LABEL summary="discovery-operator" \
      io.k8s.display-name="discovery-operator" \
      maintainer="['maintainers@okd.io']" \
      description="discovery-operator"
