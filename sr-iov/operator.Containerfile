FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default ./sr-iov/operator ./sr-iov/operator
COPY --chown=default ./.git/modules/sr-iov/operator .git/modules/sr-iov/operator

WORKDIR /opt/app-root/src/sr-iov/operator
RUN make _build-manager BIN_PATH=build/_output/cmd

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/sr-iov/operator/build/_output/cmd/manager /usr/bin/sriov-network-operator
COPY --from=builder /opt/app-root/src/sr-iov/operator/manifests /manifests

COPY ./sr-iov/operator/bindata /bindata
ENV OPERATOR_NAME=sriov-network-operator
ENV CLUSTER_TYPE=openshift
CMD ["/usr/bin/sriov-network-operator"]

LABEL io.k8s.display-name="OKD sriov-network-operator" \
      io.k8s.description="This is the component that manange and config sriov component in OKD cluster"
