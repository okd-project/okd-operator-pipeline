ARG OCP_SHORT

FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default . .

RUN GO111MODULE=on go build --mod=vendor -o build/_output/bin/manager ./cmd/handler/

FROM registry.ci.openshift.org/origin/scos-$OCP_SHORT:base-stream9

RUN \
    dnf -y update && \
    dnf -y install \
        nmstate \
        iputils \
        iproute && \
    dnf clean all


COPY --from=builder /opt/app-root/src/build/_output/bin/manager  /usr/bin/

ENTRYPOINT ["/usr/bin/manager"]

LABEL io.k8s.display-name="kubernetes-nmstate-handler" \
      io.k8s.description="Configure node networking through Kubernetes API" \
      org.opencontainers.image.authors="OKD Community <maintainers@okd.io"
