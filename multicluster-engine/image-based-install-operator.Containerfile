FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV COMPONENT_NAME=image-based-install-operator
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default image-based-install-operator .

RUN CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -tags strictfipsruntime -a -o manager cmd/manager/main.go
RUN CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -tags strictfipsruntime -a -o server cmd/server/main.go


FROM quay.io/centos/centos:stream9-minimal

#RUN microdnf -y update && microdnf clean all

RUN INSTALL_PKGS="nmstate-libs nmstate" && \
    microdnf install -y $INSTALL_PKGS --nobest && \
    microdnf clean all && \
    rm -rf /var/cache/{yum,dnf,microdnf}/*

ARG DATA_DIR=/data
RUN mkdir $DATA_DIR && chmod 775 $DATA_DIR

WORKDIR /
COPY --from=builder /opt/app-root/src/manager /usr/local/bin/
COPY --from=builder /opt/app-root/src/server /usr/local/bin/
USER 65532:65532

ENTRYPOINT ["/usr/local/bin/manager"]

LABEL summary="image-based-install-operator" \
      io.k8s.display-name="image-based-install-operator" \
      maintainer="['maintainers@okd.io']" \
      description="image-based-install-operator"

