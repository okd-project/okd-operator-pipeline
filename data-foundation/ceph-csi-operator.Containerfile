FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

COPY --chown=default ./ceph-csi-operator .

RUN go version | tee -a ./go.version

RUN CGO_ENABLED=0 GOOS=linux go build -mod=vendor -a -o bin/manager "./cmd/"

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/manager

COPY --from=builder /opt/app-root/src/bin/manager "$OPBIN"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OKD Data Foundation Ceph CSI Operator" \
    summary="Provides the latest Ceph CSI Operator package for OKD Data Foundation." \
    io.k8s.display-name="Ceph CSI Operator" \
    io.k8s.description="Ceph CSI Operator container"

RUN chmod +x "$OPBIN"

ENTRYPOINT ["/manager"]