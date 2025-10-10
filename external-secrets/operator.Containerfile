FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default operator .

RUN make build --warn-undefined-variables

FROM registry.access.redhat.com/ubi9/ubi:latest

COPY --from=builder /opt/app-root/src/bin/external-secrets-operator /bin/external-secrets-operator
COPY operator/LICENSE /licenses/

USER 65534:65534

LABEL summary="external-secrets-operator" \
      maintainer="maintainers@okd.io" \
      io.k8s.display-name="openshift-external-secrets-operator" \
      io.k8s.description="external-secrets-operator-container"

ENTRYPOINT ["/bin/external-secrets-operator"]
