FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS builder

COPY --chown=default ./descheduler .

RUN make build --warn-undefined-variables

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/descheduler /usr/bin/
LABEL io.k8s.display-name="Descheduler for OKD and Kubernetes" \
      io.k8s.description="This is a component of OKD for the Descheduler" \
      io.openshift.tags="okd,descheduler"

USER nobody
