ARG CEPH_IMG

# Build stage 1
#
# Since 5.0 the metrics exporter links against librados/librbd/libcephfs through go-ceph
# (CGO), so it is built inside the OKD ceph image where the matching Ceph headers live,
# the same way ceph-csi.Containerfile does.
FROM $CEPH_IMG as builder

ARG CI_VERSION

ENV GOFLAGS=''
ENV GOPATH=/go
ENV CGO_ENABLED=1

RUN microdnf install -y librados-devel librbd-devel libcephfs-devel go git gcc

WORKDIR /src/ocs-operator

COPY ./ocs-operator .

RUN go version | tee ./go.version

# The go-ceph release tag must match the Ceph release in the OKD ceph image (Tentacle, 20.x)
RUN GOOS=linux go build -a -tags netgo,osusergo,tentacle -ldflags "-X github.com/red-hat-storage/ocs-operator/v4/version.Version=${CI_VERSION}" -o bin/metrics-exporter ./metrics/main.go

# Build stage 2

FROM $CEPH_IMG

ENV MEBIN=/usr/local/bin/metrics-exporter

COPY --from=builder /src/ocs-operator/bin/metrics-exporter "$MEBIN"
COPY --from=builder /src/ocs-operator/go.version /go.version

LABEL description="OKD Container Storage Metrics Exporter" \
    summary="Provides the latest OCS Metrics Exporter package for OKD Data Foundation." \
    io.k8s.display-name="OCS Metrics Exporter based on UBI 9" \
    io.k8s.description="OCS Metrics Exporter container based on UBI 9 Image"

RUN chmod +x "$MEBIN"

# verify that all dynamically linked libraries are available
RUN [ $(ldd "$MEBIN" | grep -c '=> not found') = '0' ]

USER operator

ENTRYPOINT ["/usr/local/bin/metrics-exporter"]
