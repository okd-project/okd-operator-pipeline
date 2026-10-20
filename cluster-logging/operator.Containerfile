FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1

COPY --chown=default ./cluster-logging/operator ./cluster-logging/operator
COPY --chown=default .git .git

WORKDIR /opt/app-root/src/cluster-logging/operator
RUN make build BUILD_OPTS="-tags strictfipsruntime"

FROM quay.io/centos/centos:stream9

RUN INSTALL_PKGS=" \
      rsync \
      file \
      xz \
      " && \
    dnf update -y && \
    dnf install -y --nodocs --setopt=install_weak_deps=0 $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    dnf clean all && \
    mkdir /tmp/ocp-clo && \
    chmod og+w /tmp/ocp-clo

COPY --from=builder /opt/app-root/src/cluster-logging/operator/bin/cluster-logging-operator /usr/bin/
COPY --from=builder /opt/app-root/src/cluster-logging/operator/bin/must-gather /usr/bin/

RUN ln -s /usr/bin/must-gather /usr/bin/gather

USER 1000

# this is required because the operator invokes a script as `bash scripts/cert_generation.sh`
WORKDIR /usr/bin
CMD ["/usr/bin/cluster-logging-operator"]

LABEL io.k8s.display-name="Cluster Logging Operator" \
      io.k8s.description="This is a component of OKD that manages the lifecycle of the Aggregated logging stack."
