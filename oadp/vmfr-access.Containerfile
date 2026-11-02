# Upstream uses fedora:42, which is past end of life.
FROM registry.fedoraproject.org/fedora:44

RUN dnf install -y \
        --setopt=install_weak_deps=False \
        --setopt=tsflags=nodocs \
        libguestfs-tools \
        libguestfs-xfs \
        qemu-img \
        fuse \
        fuse-libs \
        e2fsprogs \
        xfsprogs \
        btrfs-progs \
        ntfs-3g \
        dosfstools \
        lvm2 \
        parted \
        kpartx \
        gdisk \
        file \
        util-linux \
        findutils \
        coreutils \
        python3 \
    && dnf clean all \
    && rm -rf /var/cache/dnf

COPY ./vm-file-restore/containers/oadp-vmfr-access/scripts/detect-and-mount.sh /usr/local/bin/detect-and-mount.sh
COPY ./vm-file-restore/containers/oadp-vmfr-access/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/detect-and-mount.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /mnt/volumes /mnt/filesystems /var/www/files

# The controller runs this image as UID and GID 107, the qemu user, which owns the VM disks.
RUN chown -R 107:107 /var/www/files /mnt/volumes /mnt/filesystems && \
    chmod -R u+rwX,g+rwX /var/www/files /mnt/volumes /mnt/filesystems

WORKDIR /var/www/files

USER 107

CMD ["/usr/local/bin/entrypoint.sh"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP VM File Access" \
        io.k8s.description="OKD API for Data Protection - VM disk image and filesystem tools for VM file restore" \
        summary="OKD API for Data Protection - VM File Access" \
        base-image="registry.fedoraproject.org/fedora:44" \
        maintainer="OKD Community <maintainers@okd.io>"
