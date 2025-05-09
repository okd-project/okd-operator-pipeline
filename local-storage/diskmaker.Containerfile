FROM registry.access.redhat.com/ubi9/go-toolset:1.22 AS builder

COPY --chown=default ./operator .

RUN make build-diskmaker

FROM quay.io/centos/centos:stream9-minimal

COPY --from=builder /opt/app-root/src/_output/bin/diskmaker /usr/bin/
COPY --from=builder /opt/app-root/src/_output/bin/diskmaker /usr/bin/
COPY --from=builder /opt/app-root/src/hack/scripts /scripts

RUN microdnf install -y e2fsprogs xfsprogs && microdnf clean all && rm -rf /var/cache/yum

ENTRYPOINT ["/usr/bin/diskmaker"]