FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOFLAGS="-p=4"

COPY --chown=default ./loki/operator .

RUN go build -tags strictfipsruntime -a -o ./passthrough-gateway ./cmd/passthrough-gateway/main.go


FROM quay.io/centos/centos:stream9 AS base

COPY --from=builder /opt/app-root/src/passthrough-gateway /passthrough-gateway

USER 65532:65532

ENTRYPOINT ["/passthrough-gateway"]

LABEL io.k8s.display-name="OKD Loki Passthrough Gateway" \
      io.k8s.description="Passthrough gateway deployed by the OKD Loki Operator for LokiStacks in passthrough tenancy mode."
