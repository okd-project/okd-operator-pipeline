FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

COPY --chown=default ./sr-iov/operator ./sr-iov/operator
COPY --chown=default .git/ .git/

WORKDIR /opt/app-root/src/sr-iov/operator
RUN make _build-sriov-network-config-daemon BIN_PATH=build/_output/cmd

FROM quay.io/centos/centos:stream9

RUN yum -y update && ARCH_DEP_PKGS=$(if [ "$(uname -m)" != "s390x" ]; then echo -n mstflint ; fi) && yum -y install pciutils hwdata $ARCH_DEP_PKGS && yum clean all
COPY --from=builder /opt/app-root/src/sr-iov/operator/build/_output/cmd/sriov-network-config-daemon /usr/bin/
COPY ./sr-iov/operator/bindata /bindata
ENV PLUGINSPATH=/plugins
ENV CLUSTER_TYPE=openshift
CMD ["/usr/bin/sriov-network-config-daemon"]

LABEL io.k8s.display-name="OKD sriov-network-config-daemon" \
      io.k8s.description="This is a daemon that manage and config sriov network devices in OKD cluster"
