FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV COMPONENT_NAME=installer
ENV COMPONENT_VERSION=1.0.0
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ENV USER_UID=1001 \
    USER_NAME=assisted-installer

COPY --chown=default assisted-installer .

RUN CGO_ENABLED=1 go build -tags strictfipsruntime -o installer src/main/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=0

RUN microdnf install -y util-linux && microdnf clean all
RUN microdnf -y update && microdnf clean all

COPY --from=builder /opt/app-root/src/installer /installer
COPY --from=builder /opt/app-root/src/deploy/assisted-installer-controller /assisted-installer-controller/deploy

ENTRYPOINT ["/installer"]

USER ${USER_UID}

LABEL summary="OKD Assisted Installer" \
      io.k8s.display-name="OKD Assisted Installer" \
      maintainer="OKD Community <maintainers@okd.io>" \
      description="OKD Assisted Installer"
