FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV COMPONENT_NAME=assisted-image-service
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ENV USER_UID=1001 \
    USER_NAME=assisted-installer

COPY --chown=default assisted-image-service .

RUN GO111MODULE=on go build -tags strictfipsruntime -o assisted-image-service main.go

# DEBUG
RUN pwd
RUN ls -l

FROM quay.io/centos/centos:stream9-minimal

ARG DATA_DIR=/data
RUN mkdir $DATA_DIR && chmod 775 $DATA_DIR
VOLUME $DATA_DIR
ENV DATA_DIR=$DATA_DIR

# DEBUG
RUN pwd
RUN ls -l

## Install nmstate - MGMT-18578
#RUN INSTALL_PKGS="nmstate nmstate-devel nmstate-libs" && \
#    microdnf install -y $INSTALL_PKGS --nobest && \
#    microdnf clean all

RUN microdnf -y update && microdnf install -y cpio squashfs-tools && microdnf clean all

COPY --from=builder /opt/app-root/src/assisted-image-service /assisted-image-service

CMD ["/assisted-image-service"]

LABEL summary="OKD Assisted Image Service" \
      io.k8s.display-name="OKD Assisted Image Service" \
      maintainer="OKD Community <maintainers@okd.io>" \
      description="OKD Assisted Image Service"
