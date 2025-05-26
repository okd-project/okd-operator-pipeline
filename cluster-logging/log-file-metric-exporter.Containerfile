FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1

COPY --chown=default ./log-file-metric-exporter .

RUN make build LDFLAGS="-tags strictfipsruntime"

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/bin/log-file-metric-exporter  /usr/local/bin/.

RUN chmod +x /usr/local/bin/log-file-metric-exporter

CMD ["/usr/local/bin/log-file-metric-exporter", "-verbosity=2", "-dir=/var/log/containers", "-http=:2112"]

LABEL io.k8s.display-name="OKD LogFileMetric Exporter" \
      io.k8s.description="OKD LogFileMetric Exporter component of OKD Cluster Logging"

