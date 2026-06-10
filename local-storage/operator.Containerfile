FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS builder

COPY --chown=default ./operator .
RUN make build-operator

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/_output/bin/local-storage-operator /usr/bin/
COPY ./operator/config/manifests /manifests

ENTRYPOINT ["/usr/bin/local-storage-operator"]
