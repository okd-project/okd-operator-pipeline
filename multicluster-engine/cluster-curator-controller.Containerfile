FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=cluster-curator-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default cluster-curator-controller .

# RUN make compile-curator
RUN go mod vendor
RUN go build -tags strictfipsruntime -o build/_output/curator ./cmd/curator/curator.go
RUN go build -tags strictfipsruntime -o build/_output/manager ./cmd/manager/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=1001

COPY --from=builder /opt/app-root/src/build/_output/curator .
COPY --from=builder /opt/app-root/src/build/_output/manager .

USER ${USER_UID}

LABEL summary="cluster-curator-controller" \
      io.k8s.display-name="cluster-curator-controller" \
      maintainer="['maintainers@okd.io']" \
      description="cluster-curator-controller"
