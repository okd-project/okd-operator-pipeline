FROM registry.access.redhat.com/ubi9/go-toolset:1.23 as builder

ENV GOFLAGS=''

COPY --chown=default ./container-object-storage-interface-provisioner-sidecar .

RUN go version | tee ./go.version
RUN GOOS=linux go build -a -o bin/objectstorage-sidecar ./cmd/objectstorage-sidecar

# Build stage 2
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

ENV OSSBIN=/usr/local/bin/objectstorage-sidecar

COPY --from=builder /opt/app-root/src/bin/objectstorage-sidecar "$OSSBIN"
COPY --from=builder /opt/app-root/src/go.version /go.version


LABEL description="OpenShift Data Foundation Container Object Storage Sidecar" \
    summary="Provides the latest OpenShift Data Foundation Container Object Storage Sidecar." \
    io.k8s.display-name="ODF COSI sidecar based on RHEL 9" \
    io.k8s.description="ODF COSI sidecar based on Red Hat Enterprise Linux 9 Image"

RUN chmod +x "$OSSBIN"

ENTRYPOINT ["/usr/local/bin/objectstorage-sidecar"]