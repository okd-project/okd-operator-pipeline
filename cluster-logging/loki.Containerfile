FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOFLAGS="-mod=vendor -p=4"

ENV BUILD_VERSION=3.7.3
ARG SOURCE_GIT_COMMIT
ENV LOKI_VPREFIX="github.com/grafana/loki/v3/pkg/util/build"

COPY --chown=default ./loki-server .

RUN touch loki-build-image/.uptodate && mkdir -p build
RUN go build -ldflags "-s -w -X ${LOKI_VPREFIX}.Branch=upstream-v${BUILD_VERSION} -X ${LOKI_VPREFIX}.Version=v${BUILD_VERSION} -X ${LOKI_VPREFIX}.Revision=${SOURCE_GIT_COMMIT} -X ${LOKI_VPREFIX}.BuildDate=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" -tags strictfipsruntime -o cmd/loki/loki ./cmd/loki/

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/cmd/loki/loki /usr/bin/loki
COPY --from=builder /opt/app-root/src/cmd/loki/loki-docker-config.yaml /etc/loki/local-config.yaml

ENTRYPOINT ["/usr/bin/loki"]
CMD ["-config.file=/etc/loki/local-config.yaml"]

LABEL io.k8s.display-name="OKD Loki" \
      io.k8s.description="Horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus."
