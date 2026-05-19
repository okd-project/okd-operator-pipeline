FROM registry.access.redhat.com/ubi9-minimal:9.7

USER 0

RUN microdnf install -y shadow-utils tar gzip && \
    microdnf clean all && rm -rf /var/cache/yum

# Download pre-built oras binary from GitHub releases
RUN ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" && \
    ORAS_VERSION="1.2.2" && \
    curl -fsSL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_${ARCH}.tar.gz" \
         -o /tmp/oras.tar.gz && \
    tar -xzf /tmp/oras.tar.gz -C /tmp oras && \
    mv /tmp/oras /usr/bin/oras && \
    chmod +x /usr/bin/oras && \
    rm /tmp/oras.tar.gz && \
    oras version

RUN useradd -u 1000 -g 0 -m oras && \
    mkdir -p /home/oras/ && \
    chown -R oras:0 /home/oras

COPY --chown=1000:0 ./operator/project-backup/entrypoint.sh /
COPY --chown=1000:0 ./operator/project-backup/workspace-recovery.sh /

RUN chmod +x /entrypoint.sh /workspace-recovery.sh

USER 1000

ENTRYPOINT ["/entrypoint.sh"]
