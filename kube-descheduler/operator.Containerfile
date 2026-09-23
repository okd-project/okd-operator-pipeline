FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

COPY --chown=default ./operator .

RUN make build --warn-undefined-variables \
    && gzip cluster-kube-descheduler-operator-tests-ext

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/cluster-kube-descheduler-operator /usr/bin/
COPY --from=builder /opt/app-root/src/cluster-kube-descheduler-operator-tests-ext.gz /usr/bin/
COPY --from=builder /opt/app-root/src/soft-tainter /usr/bin/
COPY --from=builder /opt/app-root/src/manifests /manifests
COPY --from=builder /opt/app-root/src/metadata /metadata
RUN mkdir /licenses
COPY --from=builder /opt/app-root/src/LICENSE /licenses/.
LABEL io.k8s.display-name="OKD Descheduler Operator" \
      io.k8s.description="This is a component of OKD and manages the descheduler" \
      io.openshift.tags="okd,cluster-kube-descheduler-operator"

USER nobody
