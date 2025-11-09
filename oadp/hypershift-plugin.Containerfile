FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default ./hypershift-plugin .

ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -v -mod=vendor -tags strictfipsruntime -o ./bin/hypershift-oadp-plugin .


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && microdnf -y install openssl && microdnf -y reinstall tzdata && microdnf clean all
RUN mkdir /plugins

COPY --from=builder /opt/app-root/src/bin/hypershift-oadp-plugin /plugins/
USER 65534:65534
ENTRYPOINT ["/bin/bash", "-c", "cp /plugins/* /target/."]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OKD API for Data Protection Hypershift Velero Plugin" \
        io.k8s.description="OKD API for Data Protection - Hypershift Velero Plugin" \
        summary="OKD API for Data Protection - Hypershift Velero Plugin" \
        maintainer="OKD Community <maintainers@okd.io>"
