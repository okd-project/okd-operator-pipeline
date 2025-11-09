FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

ARG CI_VERSION

COPY --chown=default ./kubernetes-csi-addons .

RUN go version | tee -a ./go.version

RUN make GIT_TAG=${CI_VERSION} build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/csi-addons-manager

COPY --from=builder /opt/app-root/src/bin/csi-addons-manager "$OPBIN"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OpenShift Data Foundation CSI addons Operator" \
    summary="Provides the latest CSI addons Controller/Operator package for OpenShift Data Foundation." \
    io.k8s.display-name="ODF CSI addons Operator based on RHEL 9" \
    io.k8s.description="OpenShift Data Foundation CSI addons Operator container based on Red Hat Enterprise Linux 9 Image" 

RUN chmod +x "$OPBIN"

ENTRYPOINT ["/csi-addons-manager"]