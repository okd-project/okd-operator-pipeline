FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOFLAGS="-p=4"

COPY --chown=default ./loki/operator .

RUN go build -tags strictfipsruntime -a -o ./manager ./cmd/loki-operator/main.go


FROM quay.io/centos/centos:stream9 AS base

COPY --from=builder /opt/app-root/src/manager /manager

ENTRYPOINT ["/manager"]

LABEL io.k8s.display-name="OKD Loki Operator" \
      io.k8s.description="OKD Loki Operator to manage LokiStack installs for OKD Logging."
