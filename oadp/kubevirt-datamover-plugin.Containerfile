FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

COPY --chown=default ./kubevirt-datamover-plugin .

RUN GOOS=linux go build -installsuffix "static" -o _output/kubevirt-datamover-plugin ./kubevirt-datamover-plugin


FROM registry.access.redhat.com/ubi9-minimal:latest

RUN mkdir /plugins
COPY --from=builder /opt/app-root/src/_output/kubevirt-datamover-plugin /plugins/
USER 65534:65534
ENTRYPOINT ["/bin/bash", "-c", "cp /plugins/* /target/."]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP KubeVirt Datamover Velero Plugin" \
        io.k8s.description="OKD API for Data Protection - KubeVirt Datamover Velero Plugin" \
        summary="OKD API for Data Protection - KubeVirt Datamover Velero Plugin" \
        maintainer="OKD Community <maintainers@okd.io>"
