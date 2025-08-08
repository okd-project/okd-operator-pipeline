ARG IMG_CLI

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV COMPONENT_NAME=assisted-installer-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ENV USER_UID=1001 \
    USER_NAME=assisted-installer

COPY --chown=default assisted-installer .
RUN go build -tags strictfipsruntime -o assisted-installer-controller src/main/assisted-installer-controller/assisted_installer_main.go


FROM $IMG_CLI AS cli

# Copy the specific `oc` cli corresponding to the current architecture to an arch-agnostic location
# This will need to be updated periodically as AI changes their dependencies on `oc`
RUN ARCH=$(if [ "$(arch)" == "x86_64" ]; then echo "amd64"; elif [ "$(arch)" == "aarch64" ]; then echo "arm64"; else echo $(arch); fi) && \
    cp -p /usr/share/openshift/linux_${ARCH}/oc /usr/local/bin/oc


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN PKGS=$(if [ "$(uname -m)" == "s390x" ]; then echo -n 'tar gzip rsync' ; else echo -n 'tar gzip rsync'; fi) && \
    microdnf -y install $PKGS && microdnf clean all

ENV USER_UID=0

COPY --from=cli /usr/local/bin/oc /usr/local/bin/oc
COPY --from=builder /opt/app-root/src/assisted-installer-controller /assisted-installer-controller

ENTRYPOINT ["/assisted-installer-controller"]

USER ${USER_UID}

LABEL summary="OKD Assisted Installer Controller" \
      io.k8s.display-name="OKD Assisted Installer Controller" \
      maintainer="OKD Community <maintainers@okd.io>" \
      description="OKD Assisted Installer Controller"
