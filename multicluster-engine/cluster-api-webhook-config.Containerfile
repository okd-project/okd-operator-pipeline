FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=cluster-api-webhook-config
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

WORKDIR /workspace
# Copy the Go Modules manifests
COPY --chown=default cluster-api-installer/mce-capi-webhook-config/go.mod go.mod
COPY --chown=default cluster-api-installer/mce-capi-webhook-config/go.sum go.sum
RUN go mod download

# Copy the go source
COPY --chown=default cluster-api-installer/mce-capi-webhook-config/main.go main.go
COPY --chown=default cluster-api-installer/mce-capi-webhook-config/webhook/ webhook/

# Build
RUN CGO_ENABLED=1 GO111MODULE=on go build -a -o /tmp/mce-capi-webhook-config main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /
COPY --from=builder /tmp/mce-capi-webhook-config /
USER nonroot:nonroot

ENTRYPOINT ["/mce-capi-webhook-config"]

LABEL description="Auto-labeling CAPI resources based on OKD and HyperShift namespaces" \
      io.k8s.description="Auto-labeling CAPI resources based on namespaces" \
      io.k8s.display-name="MultiCluster Engine CAPI Webhook Config" \
      name="mce-capi-webhook-config" \
      summary="Auto-labeling CAPI resources based on namespaces"
