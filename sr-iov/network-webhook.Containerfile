FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default ./sr-iov/operator ./sr-iov/operator
COPY --chown=default .git/ .git/

WORKDIR /opt/app-root/src/sr-iov/operator
RUN make _build-webhook BIN_PATH=build/_output/cmd

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/sr-iov/operator/build/_output/cmd/webhook /usr/bin/webhook

ENV CLUSTER_TYPE=openshift

USER 1001
CMD ["/usr/bin/webhook"]

LABEL io.k8s.display-name="OKD sriov-network-webhook" \
      io.k8s.description="This is an admission controller webhook that mutates and validates customer resources of sriov network operator."