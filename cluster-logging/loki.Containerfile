FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ARG VERSION

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOFLAGS="-mod=vendor -p=4"

ENV LOKI_VPREFIX="github.com/grafana/loki/pkg/util/build"

COPY --chown=default ./loki .

RUN touch loki-build-image/.uptodate && mkdir -p build
RUN go build -ldflags "-s -w -X ${LOKI_VPREFIX}.Branch=upstream-v3.4.2 -X ${LOKI_VPREFIX}.Version=v${VERSION} -X ${LOKI_VPREFIX}.Revision=abcdac1 -X ${LOKI_VPREFIX}.BuildDate=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" -tags strictfipsruntime -o cmd/loki/loki ./cmd/loki/

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/cmd/loki/loki /usr/bin/loki
COPY --from=builder /opt/app-root/src/cmd/loki/loki-local-config.yaml /etc/loki/local-config.yaml

EXPOSE 80
ENTRYPOINT ["/usr/bin/loki"]

LABEL io.k8s.display-name="OKD Loki" \
      io.k8s.description="Horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus."
