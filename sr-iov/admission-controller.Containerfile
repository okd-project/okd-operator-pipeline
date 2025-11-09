FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ADD --chown=default ./admission-controller .
RUN make

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/bin/webhook /usr/bin/
COPY --from=builder /opt/app-root/src/bin/installer /usr/bin/

USER 1001
CMD ["webhook"]

LABEL io.k8s.display-name="SRIOV Admission Controller"
