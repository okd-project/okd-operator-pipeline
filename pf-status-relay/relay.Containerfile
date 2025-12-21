FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default . .
RUN CGO_ENABLED=1 GOOS=linux go build -a -ldflags '-w' -o pf-status-relay cmd/pf-status-relay.go

FROM registry.ci.openshift.org/origin/scos-4.20:base-stream9
LABEL io.k8s.display-name="SR-IOV PF Status Relay"
LABEL io.k8s.description="This is a component of Openshift Container Platform that adjusts the link state of VFs based on the LACP status of the PFs."

COPY --from=builder /opt/app-root/src/pf-status-relay /usr/bin/pf-status-relay
ENTRYPOINT ["pf-status-relay"]
