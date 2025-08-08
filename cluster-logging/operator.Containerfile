FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1

COPY --chown=default ./cluster-logging/operator ./cluster-logging/operator
COPY --chown=default .git .git

WORKDIR /opt/app-root/src/cluster-logging/operator
RUN make build BUILD_OPTS="-tags strictfipsruntime"

FROM quay.io/centos/centos:stream9

RUN INSTALL_PKGS=" \
      openssl \
      cpio \
      rsync \
      file \
      xz \
      openshift-clients \
      " && \
    dnf update -y && \
    dnf install -y --nodocs --setopt=install_weak_deps=0 tar rsync findutils gzip iproute tcpdump pciutils util-linux nftables procps-ng yum-utils && \
    yum-config-manager --add-repo https://copr.fedorainfracloud.org/coprs/owenh/micro-okd/repo/centos-stream-9/owenh-micro-okd-centos-stream-9.repo && \
    dnf install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    dnf clean all && \
    mkdir /tmp/ocp-clo && \
    chmod og+w /tmp/ocp-clo

COPY --from=builder /opt/app-root/src/cluster-logging/operator/bin/cluster-logging-operator /usr/bin/

COPY --from=builder /opt/app-root/src/cluster-logging/operator/bundle/manifests /manifests

COPY --from=builder /opt/app-root/src/cluster-logging/operator/must-gather/collection-scripts/* /usr/bin/

USER 1000

# this is required because the operator invokes a script as `bash scripts/cert_generation.sh`
WORKDIR /usr/bin
CMD ["/usr/bin/cluster-logging-operator"]

LABEL io.k8s.display-name="Cluster Logging Operator" \
      io.k8s.description="This is a component of OKD that manages the lifecycle of the Aggregated logging stack."
