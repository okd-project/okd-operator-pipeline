FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

COPY --chown=default ./vm-file-restore/containers/side-containers/sshd/oadp-sshd.go .

RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o oadp-sshd oadp-sshd.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf install -y \
    openssh-server \
    openssh-clients \
    shadow-utils \
    passwd \
    rsync \
    bash \
    findutils \
    && microdnf clean all

# Chroot jail at /oadp
RUN mkdir -p /oadp/bin \
    && mkdir -p /oadp/lib \
    && mkdir -p /oadp/lib64 \
    && mkdir -p /oadp/usr/lib \
    && mkdir -p /oadp/usr/lib64 \
    && mkdir -p /oadp/usr/libexec/openssh \
    && mkdir -p /oadp/dev \
    && mkdir -p /oadp/.ssh

RUN cp /usr/bin/rsync /oadp/bin/ \
    && cp /usr/bin/scp /oadp/bin/ \
    && cp /bin/bash /oadp/bin/ \
    && cp /usr/libexec/openssh/sftp-server /oadp/usr/libexec/openssh/

# Library dependencies and the dynamic linker of those binaries, keeping their directories
RUN for binary in /usr/bin/rsync /usr/bin/scp /bin/bash /usr/libexec/openssh/sftp-server; do \
        echo "Copying dependencies for $binary..."; \
        ldd "$binary" 2>/dev/null | grep "=>" | awk '{print $3}' | while read lib; do \
            if [ -f "$lib" ]; then \
                case "$lib" in \
                    /lib64/*) mkdir -p /oadp/lib64 && cp -L "$lib" /oadp/lib64/ 2>/dev/null || true ;; \
                    /lib/*) mkdir -p /oadp/lib && cp -L "$lib" /oadp/lib/ 2>/dev/null || true ;; \
                    /usr/lib64/*) mkdir -p /oadp/usr/lib64 && cp -L "$lib" /oadp/usr/lib64/ 2>/dev/null || true ;; \
                    /usr/lib/*) mkdir -p /oadp/usr/lib && cp -L "$lib" /oadp/usr/lib/ 2>/dev/null || true ;; \
                esac; \
            fi; \
        done; \
        ldd "$binary" 2>/dev/null | grep -E "ld-linux|ld.so" | awk '{print $1}' | while read linker; do \
            if [ -f "$linker" ]; then \
                case "$linker" in \
                    /lib64/*) mkdir -p /oadp/lib64 && cp -L "$linker" /oadp/lib64/ 2>/dev/null || true ;; \
                    /lib/*) mkdir -p /oadp/lib && cp -L "$linker" /oadp/lib/ 2>/dev/null || true ;; \
                esac; \
            fi; \
        done; \
    done

COPY --from=builder /opt/app-root/src/oadp-sshd /oadp/bin/oadp-sshd

COPY ./vm-file-restore/containers/side-containers/sshd/entrypoint.sh /entrypoint.sh

RUN chmod 711 /oadp/bin/oadp-sshd \
    && chmod +x /entrypoint.sh \
    && chmod 755 /oadp/bin/rsync \
    && chmod 755 /oadp/bin/scp \
    && chmod 755 /oadp/bin/bash \
    && chmod 755 /oadp/usr/libexec/openssh/sftp-server

RUN chown root:root /oadp \
    && chmod 755 /oadp

# entrypoint.sh copies these to /etc at runtime, when /etc is an emptyDir
RUN mkdir -p /etc-template \
    && cp -a /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/nsswitch.conf /etc-template/ \
    && cp -a /etc/pam.d /etc-template/

EXPOSE 2222

# sshd and its chroot need root
USER root

ENTRYPOINT ["/entrypoint.sh"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP VM File Restore SSHD" \
        io.k8s.description="OKD API for Data Protection - read-only SSH, SFTP and rsync access to backup files" \
        summary="OKD API for Data Protection - VM File Restore SSHD" \
        maintainer="OKD Community <maintainers@okd.io>"
