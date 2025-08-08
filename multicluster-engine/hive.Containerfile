FROM registry.access.redhat.com/ubi8/go-toolset:1.23 AS builder_rhel8

ARG CI_VERSION
ARG CI_TAG

ENV COMPONENT_NAME=openshift-hive
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV SOURCE_GIT_TAG=$CI_TAG
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

USER root
RUN dnf install -y python3-pip
USER default

COPY --chown=default multicluster-engine/hive multicluster-engine/hive
COPY --chown=default .git .git

WORKDIR $HOME/multicluster-engine/hive

RUN GOFLAGS='-mod=vendor -p=4' make build-hiveutil


FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder_rhel9

ENV COMPONENT_NAME=openshift-hive
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV SOURCE_GIT_TAG=$CI_TAG
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

USER root
RUN dnf install -y python3-pip
USER default

COPY --chown=default multicluster-engine/hive multicluster-engine/hive
COPY --chown=default .git .git

WORKDIR $HOME/multicluster-engine/hive

RUN GOFLAGS='-mod=vendor -p=4' make build-hiveadmission build-manager build-operator && make build-hiveutil


FROM quay.io/centos/centos:stream9-minimal

RUN microdnf -y --nobest update && microdnf clean all

# ssh-agent required for gathering logs in some situations:
# libvirt libraries required for running bare metal installer.
RUN microdnf install -y openssh-clients libvirt-libs tar && microdnf clean all
RUN rm -rf /var/cache/microdnf/*

ENV REMOTE_SOURCE_DIR=/opt/app-root/src/multicluster-engine/hive

COPY --from=builder_rhel9 $REMOTE_SOURCE_DIR/bin/manager /opt/services/
COPY --from=builder_rhel9 $REMOTE_SOURCE_DIR/bin/hiveadmission /opt/services/
COPY --from=builder_rhel9 $REMOTE_SOURCE_DIR/bin/operator /opt/services/hive-operator

COPY --from=builder_rhel8 $REMOTE_SOURCE_DIR/bin/hiveutil /usr/bin/hiveutil.rhel8
COPY --from=builder_rhel9 $REMOTE_SOURCE_DIR/bin/hiveutil /usr/bin/hiveutil

# Hacks to allow writing known_hosts, homedir is / by default in OpenShift.
# Bare metal installs need to write to $HOME/.cache, and $HOME/.ssh for as long as
# we're hitting libvirt over ssh. OpenShift will not let you write these directories
# by default so we must setup some permissions here.
ENV HOME /home/hive
RUN mkdir -p /home/hive && \
    chgrp -R 0 /home/hive && \
    chmod -R g=u /home/hive

RUN mkdir -p /output/hive-trusted-cabundle && \
    chgrp -R 0 /output/hive-trusted-cabundle && \
    chmod -R g=u /output/hive-trusted-cabundle

ENTRYPOINT ["/opt/services/manager"]

LABEL summary="hive" \
      io.k8s.display-name="hive" \
      maintainer="['maintainers@okd.io']" \
      description="hive"
