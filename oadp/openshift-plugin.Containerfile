FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder
COPY --chown=1001:0 $REMOTE_SOURCE $REMOTE_SOURCE_DIR
RUN mkdir -p $REMOTE_SOURCE_DIR/src/github.com/konveyor/openshift-velero-plugin
RUN mv $REMOTE_SOURCE_DIR/app/* $REMOTE_SOURCE_DIR/src/github.com/konveyor/openshift-velero-plugin
WORKDIR $REMOTE_SOURCE_DIR/src/github.com/konveyor/openshift-velero-plugin
ENV BUILDTAGS containers_image_ostree_stub exclude_graphdriver_devicemapper exclude_graphdriver_btrfs containers_image_openpgp exclude_graphdriver_overlay include_gcs include_oss strictfipsruntime
ENV BIN velero-plugins
ENV GOEXPERIMENT strictfipsruntime
RUN source $CACHITO_ENV_FILE && go build -installsuffix "static" -tags "$BUILDTAGS" -mod=mod -o _output/$BIN ./$BIN

# FROM ubuntu:bionic //
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
RUN microdnf -y update && microdnf -y install openssl && microdnf -y reinstall tzdata && microdnf clean all
RUN mkdir /plugins
COPY --from=builder $REMOTE_SOURCE_DIR/src/github.com/konveyor/openshift-velero-plugin/_output/$BIN /plugins/
USER 65534:65534
ENTRYPOINT ["/bin/bash", "-c", "cp /plugins/* /target/."]

LABEL \
                version="1.5.2" \
        name="oadp/oadp-velero-plugin-rhel9" \
        License="Apache License 2.0" \
        io.k8s.display-name="OADP Velero Plugin" \
                io.k8s.description="OpenShift API for Data Protection - Velero Plugin" \
                                summary="OpenShift API for Data Protection - Velero Plugin" \
        maintainer="OpenShift API for Data Protection Team <oadp-team@redhat.com>"
