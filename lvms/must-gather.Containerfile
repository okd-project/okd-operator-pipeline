ARG IMG_CLI

FROM $IMG_CLI  AS ose-cli

FROM quay.io/centos/centos:stream9-minimal

RUN microdnf update -y && \
    microdnf install -y --nodocs --setopt=install_weak_deps=0 tar rsync findutils gzip iproute tcpdump pciutils util-linux nftables procps-ng && \
    microdnf clean all && \
    rm -rf /var/cache/*

COPY --from=ose-cli /usr/bin/oc /usr/bin/oc

# Copy all collection scripts to /usr/bin
COPY operator/must-gather/collection-scripts/* /usr/bin/

RUN mkdir /licenses
COPY ./operator/LICENSE /licenses


ENTRYPOINT ["/usr/bin/gather"]
