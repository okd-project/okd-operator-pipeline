FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default ./metrics-exporter .

RUN make clean && GO_TAGS="" GO_BUILD_OPTS=CGO_ENABLED=1 make build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/build/* /usr/bin/
EXPOSE 9808
ENTRYPOINT ["sriov-exporter"]

LABEL io.k8s.display-name="OKD SR-IOV Network Metrics Exporter-operator" \
      io.k8s.description="This component exports metrics related to VF configured through the SR-IOV network operator."

