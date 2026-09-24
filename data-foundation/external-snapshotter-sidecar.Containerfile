FROM registry.access.redhat.com/ubi10/go-toolset:1.26 as builder

COPY --chown=default external-snapshotter .

RUN go version | tee -a ./go.version

RUN GOOS=linux go build -mod=vendor -a -o bin/csi-snapshotter cmd/csi-snapshotter/main.go

FROM registry.access.redhat.com/ubi10/ubi-minimal:latest

ENV SNAPSHOTTERBIN=/csi-snapshotter
ARG BUILD_SRC=/opt/app-root/src

COPY --from=builder $BUILD_SRC/bin/csi-snapshotter "$SNAPSHOTTERBIN"
COPY --from=builder $BUILD_SRC/go.version /go.version

RUN chmod +x "$SNAPSHOTTERBIN"

ENTRYPOINT ["/csi-snapshotter"]

LABEL io.k8s.display-name="ODF exteranl snapshotter sidecar based on UBI 9"
LABEL io.k8s.description="OKD Data Foundation Exteranl Snapshotter sidecar container based on UBI 9 Image"
