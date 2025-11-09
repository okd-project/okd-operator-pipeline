FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=1001:0 $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app
ENV GOEXPERIMENT strictfipsruntime
RUN source $CACHITO_ENV_FILE && CGO_ENABLED=1 GOOS=linux go build -v -mod=mod -tags strictfipsruntime -o $REMOTE_SOURCE_DIR/bin/velero-plugin-for-aws ./velero-plugin-for-aws

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
RUN microdnf -y update && microdnf -y install openssl && microdnf -y reinstall tzdata && microdnf clean all
RUN mkdir /plugins
COPY --from=builder $REMOTE_SOURCE_DIR/bin/velero-plugin-for-aws /plugins/
USER 65534:65534
ENTRYPOINT ["/bin/bash", "-c", "cp /plugins/* /target/."]

LABEL \
                version="1.5.2" \
        name="oadp/oadp-velero-plugin-for-legacy-aws-rhel9" \
        License="Apache License 2.0" \
        io.k8s.display-name="OADP Velero Plugin for Legacy AWS" \
                io.k8s.description="OpenShift API for Data Protection - Velero Plugin for Legacy AWS" \
                                summary="OpenShift API for Data Protection - Velero Plugin for Legacy AWS" \
        maintainer="OpenShift API for Data Protection Team <oadp-team@redhat.com>"
