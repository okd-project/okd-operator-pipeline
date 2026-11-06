FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

COPY --chown=default operator .
COPY --chown=default operator/LICENSE /licenses/

# `make build` depends on `generate`, which needs k8s.io/code-generator -- not
# vendored, so it fails under -mod=vendor. The generated code is already
# committed. Build directly instead, as Red Hat's operand Dockerfiles do.
ENV GO_BUILD_TAGS=strictfipsruntime,openssl
ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOFLAGS=""

RUN go build -o cert-manager-operator -ldflags '-w -s' -tags "${GO_BUILD_TAGS}" main.go

FROM quay.io/centos/centos:stream9

ARG SOURCE_DIR="/opt/app-root/src"

COPY --from=builder $SOURCE_DIR/cert-manager-operator /usr/bin/
COPY --from=builder /licenses /licenses

USER 65534:65534

LABEL io.k8s.display-name="OKD Cert-Manager Operator " \
      io.k8s.description="Manages the lifecycle of cert-manager in OKD clusters"

ENTRYPOINT ["/usr/bin/cert-manager-operator"]
