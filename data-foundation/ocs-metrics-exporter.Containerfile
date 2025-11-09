ARG CEPH_IMG

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 as builder

ARG CI_VERSION

ENV GOFLAGS=''

COPY --chown=default ./ocs-operator .

WORKDIR /opt/app-root/src/metrics

RUN go version | tee ./go.version
RUN GOOS=linux go build -a -ldflags "-X github.com/red-hat-storage/ocs-operator/v4/version.Version=${CI_VERSION}" -o ../bin/metrics-exporter ./main.go

# Build stage 2

FROM $CEPH_IMG

ENV MEBIN=/usr/local/bin/metrics-exporter

COPY --from=builder /opt/app-root/src/bin/metrics-exporter "$MEBIN"
COPY --from=builder /opt/app-root/src/metrics/go.version /go.version


LABEL description="OKD Container Storage Metrics Exporter" \
    summary="Provides the latest OCS Metrics Exporter package for OKD Data Foundation." \
    io.k8s.display-name="OCS Metrics Exporter based on UBI 9" \
    io.k8s.description="OCS Metrics Exporter container based on UBI 9 Image"

RUN chmod +x "$MEBIN"

USER operator

ENTRYPOINT ["/usr/local/bin/metrics-exporter"]
