FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

COPY --chown=default ./device-plugin .

RUN make clean && \
    GO_BUILD_OPTS=CGO_ENABLED=1 GO_TAGS=" " make build

FROM registry.access.redhat.com/ubi9/ubi:latest

ENV INSTALL_PKGS "hwdata"
RUN dnf install -y "hwdata" && \
    rpm -V $INSTALL_PKGS && \
    dnf clean all

COPY --from=builder /opt/app-root/src/build/sriovdp /usr/bin/

WORKDIR /

COPY ./device-plugin/images/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

LABEL io.k8s.display-name="SRIOV Network Device Plugin"