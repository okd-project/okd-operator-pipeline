FROM $IMG_CLI AS ose-cli

FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder


WORKDIR $HOME/operator
COPY --chown=default ./operator .

# mustgather
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=mod -tags strictfipsruntime -o ./gather cmd/main.go


# kopia
WORKDIR $HOME/kopia/
COPY --chown=default ./kopia .
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=mod -tags strictfipsruntime -o ./kopia

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
#  be reconciled in oadp-velero/Dockerfile.in for consistency.        #
#######################################################################
# BEGIN                                                               #
#######################################################################

# velero
WORKDIR $HOME/velero
COPY --chown=default ./velero .
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=mod -ldflags '-X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=v1.16.1-OADP' -tags strictfipsruntime -o ./bin/velero ./cmd/velero

# restic
WORKDIR $HOME/restic
COPY --chown=default ./restic .
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -a -mod=mod -tags strictfipsruntime -o ./bin/restic ./cmd/restic

#######################################################################
# END                                                                 #
#######################################################################

ENV INSTALLATION_NAMESPACE openshift-adp


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && microdnf -y reinstall tzdata && microdnf clean all
RUN microdnf -y install openssl rsync tar gzip && microdnf -y clean all

ARG BUILD_DIR=/opt/app-root/src

COPY --from=builder $BUILD_DIR/velero/bin/velero /usr/bin/velero
COPY --from=builder $BUILD_DIR/restic/bin/restic /usr/bin/restic
COPY --from=ose-cli /usr/bin/oc /usr/bin/oc
COPY --from=builder $BUILD_DIR/kopia/kopia /usr/bin/kopia
COPY --from=builder $BUILD_DIR/mustgather/gather /usr/bin/gather
COPY --from=builder $BUILD_DIR/mustgather/deprecated/gather_* /usr/bin/

ENTRYPOINT /usr/bin/gather

LABEL summary="OKD API for Data Protection - Must Gather" \
      io.k8s.display-name="OKD API for Data Protection - Must Gather" \
      description="OKD API for Data Protection - Must Gather" \
      maintainer="OKD Community <maintainers@okd.io>"
