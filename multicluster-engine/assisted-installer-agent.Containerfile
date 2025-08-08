ARG IMG_CLI

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USER_UID=1001 \
    USER_NAME=assisted-installer

ENV COMPONENT_NAME=assisted-installer-agent
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default assisted-installer-agent .

RUN CGO_FLAG=1 make build


FROM $IMG_CLI AS cli

# Copy the specific `oc` cli corresponding to the current architecture to an arch-agnostic location
# This will need to be updated periodically as AI changes their dependencies on `oc`
RUN ARCH=$(if [ "$(arch)" == "x86_64" ]; then echo "amd64"; elif [ "$(arch)" == "aarch64" ]; then echo "arm64"; else echo $(arch); fi) && \
    cp -p /usr/share/openshift/linux_${ARCH}/oc /usr/local/bin/oc


FROM quay.io/centos/centos:stream9-minimal

ENV USER_UID=0

RUN microdnf -y update && microdnf clean all

RUN PKGS="findutils iputils podman ipmitool file sg3_utils fio nmap dhclient tar chrony util-linux hwdata" && \
    X86_PKGS=$(if [ "$(uname -m)" == "x86_64" ]; then echo -n biosdevname dmidecode ; fi) && \
    ARM_PKGS=$(if [ "$(uname -m)" == "aarch64" ]; then echo -n dmidecode ; fi) && \
    PPC64LE_PKGS=$(if [ "$(uname -m)" == "ppc64le" ]; then echo -n '' ; fi) && \
    S390X_PKGS=$(if [ "$(uname -m)" == "s390x" ]; then echo -n '' ; fi) && \
    microdnf install -y $PKGS $X86_PKGS $ARM_PKGS $PPC64LE_PKGS $S390X_PKGS && \
    microdnf update -y systemd && \
    microdnf clean all && \
    rm -rf /var/cache/{yum,dnf,microdnf}/*

COPY --from=cli /usr/local/bin/oc /usr/local/bin/oc
COPY --from=builder /opt/app-root/src/build/agent /usr/bin/agent

# The step binaries are all symlinks to /usr/bin/agent
RUN ln -s /usr/bin/agent /usr/bin/free_addresses && \
    ln -s /usr/bin/agent /usr/bin/inventory && \
    ln -s /usr/bin/agent /usr/bin/logs_sender && \
    ln -s /usr/bin/agent /usr/bin/next_step_runner && \
    ln -s /usr/bin/agent /usr/bin/disk_speed_check

USER ${USER_UID}

LABEL summary="OKD Assisted Installer Agent" \
      io.k8s.display-name="OKD Assisted Installer" \
      maintainer="OKD Community <maintainers@okd.io>" \
      description="OKD Assisted Installer"
