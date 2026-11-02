FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

COPY --chown=default ./kubevirt-datamover-controller .

# proxy.golang.org intermittently drops module fetches mid-transfer, and go mod download has no
# retry flag.
RUN retry() { for i in 1 2 3 4 5; do "$@" && return 0; echo "retrying ($i/5): $*" >&2; sleep 5; done; return 1; }; \
    retry go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -a -o manager cmd/main.go


# CentOS Stream, because the UBI repositories do not carry qemu-img, which the datamover needs to
# turn qcow2 incremental chains into raw disk images.
FROM quay.io/centos/centos:stream9-minimal

RUN microdnf install -y qemu-img && microdnf clean all

WORKDIR /
COPY --from=builder /opt/app-root/src/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP KubeVirt Datamover Controller" \
        io.k8s.description="OKD API for Data Protection - KubeVirt Datamover Controller" \
        summary="OKD API for Data Protection - KubeVirt Datamover Controller" \
        maintainer="OKD Community <maintainers@okd.io>"
