FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default aws-legacy-plugin .

ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -v -mod=mod -tags strictfipsruntime -o ./bin/velero-plugin-for-aws ./velero-plugin-for-aws


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && microdnf -y install openssl && microdnf -y reinstall tzdata && microdnf clean all
RUN mkdir /plugins

COPY --from=builder /opt/app-root/src/bin/velero-plugin-for-aws /plugins/

USER 65534:65534
ENTRYPOINT ["/bin/bash", "-c", "cp /plugins/* /target/."]

LABEL \
        name="oadp/oadp-velero-plugin-for-legacy-aws-rhel9" \
        License="Apache License 2.0" \
        io.k8s.display-name="OADP Velero Plugin for Legacy AWS" \
        io.k8s.description="OKD API for Data Protection - Velero Plugin for Legacy AWS" \
        summary="OKD API for Data Protection - Velero Plugin for Legacy AWS" \
        maintainer="OKD Community <maintainers@okd.io>"
