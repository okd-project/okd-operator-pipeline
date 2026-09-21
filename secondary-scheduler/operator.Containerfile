FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default ./operator .

RUN make build --warn-undefined-variables

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/secondary-scheduler-operator /usr/bin/
COPY --from=builder /opt/app-root/src/manifests /manifests
COPY --from=builder /opt/app-root/src/metadata /metadata
RUN mkdir /licenses
COPY --from=builder /opt/app-root/src/LICENSE /licenses/.
LABEL io.k8s.display-name="OKD Secondary Scheduler Operator" \
      io.k8s.description="This is a component of OKD and manages the secondary scheduler" \
      io.openshift.tags="okd,secondary-scheduler-operator"

USER nobody
