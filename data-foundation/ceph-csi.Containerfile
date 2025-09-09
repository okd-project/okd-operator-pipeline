ARG CEPH_VERSION

FROM quay.io/ceph/daemon-base:latest-squid as builder

ARG CI_VERSION

ENV IMPORT_PATH=github.com/ceph/ceph-csi

RUN dnf install -y librados-devel librbd-devel libcephfs-devel go git

WORKDIR /src/

COPY data-foundation/ceph-csi data-foundation/ceph-csi
COPY .git .git

WORKDIR /src/data-foundation/ceph-csi

RUN go version | tee -a ./go.version

RUN CGO_ENABLED=1 GO111MODULE=on GOOS=linux go build -mod=mod -tags=squid,ceph_preview -a -ldflags \
    "-X $IMPORT_PATH/internal/util.GitCommit=$(git rev-parse HEAD) -X $IMPORT_PATH/internal/util.DriverVersion=${CI_VERSION} " -o bin/cephcsi "./cmd/"


# Build stage 2
FROM quay.io/ceph/ceph:v${CEPH_VERSION}

ENV CSIBIN=/usr/local/bin/cephcsi

COPY --from=builder /src/data-foundation/ceph-csi/bin/cephcsi "$CSIBIN"
COPY --from=builder /src/data-foundation/ceph-csi/go.version /go.version

LABEL description="OKD Data Foundation Ceph CSI container" \
    summary="Provides the latest Ceph CSI package for OKD Data Foundation." \
    io.k8s.display-name="ODF Ceph CSI based on UBI 9" \
    io.k8s.description="OKD Data Foundation Ceph CSI container based on UBI 9 Image"

RUN chmod +x "$CSIBIN"

ENTRYPOINT ["/usr/local/bin/cephcsi"]