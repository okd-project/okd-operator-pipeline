FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default operator .
COPY --chown=default operator/LICENSE /licenses/

RUN make build --warn-undefined-variables

FROM quay.io/centos/centos:stream9

ARG SOURCE_DIR="/opt/app-root/src"

COPY --from=builder $SOURCE_DIR/cert-manager-operator /usr/bin/
COPY --from=builder /licenses /licenses

USER 65534:65534

LABEL io.k8s.display-name="OKD Cert-Manager Operator " \
      io.k8s.description="Manages the lifecycle of cert-manager in OKD clusters"

ENTRYPOINT ["/usr/bin/cert-manager-operator"]
