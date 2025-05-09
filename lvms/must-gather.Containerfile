FROM quay.io/centos/centos:stream9-minimal

RUN microdnf update -y && \
    microdnf install -y --nodocs --setopt=install_weak_deps=0 tar rsync findutils gzip iproute tcpdump pciutils util-linux nftables procps-ng yum-utils && \
    yum-config-manager --add-repo https://copr.fedorainfracloud.org/coprs/owenh/micro-okd/repo/centos-stream-10/owenh-micro-okd-centos-stream-10.repo && \
    microdnf install -y openshift-clients && \
    microdnf clean all && \
    rm -rf /var/cache/*
# Copy all collection scripts to /usr/bin
COPY ./operator/must-gather/collection-scripts/* /usr/bin/

ENTRYPOINT ["/usr/bin/gather"]
