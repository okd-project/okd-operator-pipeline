FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

ARG CI_VERSION

COPY --chown=default ./kubernetes-csi-addons .

RUN go version | tee -a ./go.version

RUN make GIT_TAG=${CI_VERSION} build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

COPY --from=builder /opt/app-root/src/bin/csi-addons-sidecar /usr/sbin/
COPY --from=builder /opt/app-root/src/bin/csi-addons /usr/bin/
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OKD Data Foundation CSI addons Sidecar" \
    summary="Provides the latest CSI addons sidecar package for OKD Data Foundation." \
    io.k8s.display-name="ODF CSI addons sidecar based on UBI 9" \
    io.k8s.description="OKD Data Foundation CSI addons sidecar container based on UBI 9 Image"

RUN chmod +x "/usr/sbin/csi-addons-sidecar" "/usr/bin/csi-addons"

ENTRYPOINT ["/usr/sbin/csi-addons-sidecar"]