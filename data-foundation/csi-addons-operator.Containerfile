FROM registry.access.redhat.com/ubi10/go-toolset:1.26 as builder

ARG CI_VERSION

# Keep the module cache out of the source tree: HOME is /opt/app-root/src, and
# `make build` runs `go fmt ./...`, which fails on a module cache under ./go
# (go1.26.10 fetches a golang.org/fips140 snapshot there).
ENV GOPATH=/tmp/go

COPY --chown=default ./kubernetes-csi-addons .

RUN go version | tee -a ./go.version

RUN make GIT_TAG=${CI_VERSION} build

FROM registry.access.redhat.com/ubi10/ubi-minimal:latest

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