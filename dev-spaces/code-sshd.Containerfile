# UBI 8 stage to collect ubi8-specific sshd binaries
FROM registry.access.redhat.com/ubi8/ubi:8.10 as sshd-ubi8

USER 0

RUN dnf -y install libsecret openssh-server nss_wrapper-libs && \
    dnf -y clean all --enablerepo='*'

# UBI 9 final stage
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:9.7

USER 0

RUN microdnf install -y libsecret openssh-server nss_wrapper-libs && \
    microdnf -y clean all --enablerepo='*'

RUN mkdir -p /sshd-staging/ubi8 /sshd-staging/ubi9

# UBI 8 binaries
COPY --from=sshd-ubi8 \
    /usr/sbin/sshd \
    /usr/bin/ssh-keygen \
    /usr/bin/tar \
    /usr/bin/gzip \
    /usr/bin/which \
    /usr/lib64/libnss_wrapper.so \
    /usr/lib64/libpam.so.0 \
    /sshd-staging/ubi8/

# UBI 9 binaries
RUN cp \
    /usr/sbin/sshd \
    /usr/bin/ssh-keygen \
    /usr/bin/tar \
    /usr/bin/gzip \
    /usr/bin/which \
    /usr/lib64/libnss_wrapper.so \
    /usr/lib64/libpam.so.0 \
    /usr/lib64/libeconf.so.0 \
    /usr/lib64/libcrypt.so.2 \
    /sshd-staging/ubi9/

RUN chmod 644 /etc/ssh/sshd_config
RUN cp /etc/ssh/sshd_config /sshd-staging/

COPY --chown=0:0 che-code/build/scripts/sshd.init che-code/build/scripts/sshd.start /sshd-staging/

RUN mkdir -p /opt/www/code /opt/www/jetbrains
COPY che-code/build/scripts/code-sshd-page/* /opt/www/code
COPY che-code/build/scripts/jetbrains-sshd-page/* /opt/www/jetbrains

RUN chmod 644 /etc/passwd

EXPOSE 2022 3400

USER 10001
