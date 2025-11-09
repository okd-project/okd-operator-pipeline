FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

#######################################################################
#######################################################################
#                                                                     #
#      W     W    AA     RRRR     N   N    III    N   N     GGG       #
#      W     W   A  A    R   R    NN  N     I     NN  N    G          #
#      W  W  W   AAAA    RRRR     N N N     I     N N N    G  GG      #
#       W W W    A  A    R R      N  NN     I     N  NN    G   G      #
#        W W     A  A    R  RR    N   N    III    N   N     GGG       #
#                                                                     #
#  Any changes to the `velero` and `restic` sections below must also  #
#  be reconciled in oadp-mustgather/Dockerfile.in for consistency.    #
#######################################################################
# BEGIN                                                               #
#######################################################################

# velero
WORKDIR $HOME/velero/
COPY --chown=default ./velero .
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=readonly -ldflags '-X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=v1.16.1-OADP' -tags strictfipsruntime -o ./bin/velero ./cmd/velero
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=readonly -tags strictfipsruntime -o ./bin/velero-restore-helper ./cmd/velero-restore-helper
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=readonly -tags strictfipsruntime -o ./bin/velero-helper ./cmd/velero-helper

# restic
WORKDIR $HOME/restic
COPY --chown=default ./restic .
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=readonly -tags strictfipsruntime -o ./bin/restic ./cmd/restic
USER 65534:65534

#######################################################################
# END                                                                 #
#######################################################################

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
RUN microdnf -y update && microdnf -y reinstall tzdata && microdnf clean all
RUN microdnf -y install less nmap-ncat openssl && microdnf clean all

ARG BUILD_DIR=/opt/app-root/src
COPY --from=builder $BUILD_DIR/velero/bin/velero velero
COPY --from=builder $BUILD_DIR/velero/bin/velero-restore-helper velero-restore-helper
COPY --from=builder $BUILD_DIR/velero/bin/velero-helper velero-helper
COPY --from=builder $BUILD_DIR/restic/bin/restic /usr/bin/restic

RUN mkdir -p /home/velero
RUN chmod -R 777 /home/velero

USER 65534:65534
ENV HOME=/home/velero

ENTRYPOINT ["/velero"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP Velero" \
        io.k8s.description="OKD API for Data Protection - Velero" \
        summary="OKD API for Data Protection - Velero" \
        maintainer="OKD Community <maintainers@okd.io>"
