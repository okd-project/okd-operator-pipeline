# version_arg setting before first FROM to be available to all stages
ARG version_arg="ACM-0.12.1-5c60cbc"

FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/volsync/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached

######################################################################
# Build the manager binary
#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS manager-builder

# Dummy copy command to force execution of drifter
COPY --from=drifter $REMOTE_SOURCES_DIR/volsync/app/Dockerfile.cached /tmp/Dockerfile.cached

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG version_arg
ENV version="${version_arg}"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/volsync/app

RUN source $REMOTE_SOURCES_DIR/volsync/cachito.env && GO111MODULE=on go build -a -o manager -ldflags "-X=main.volsyncVersion=${version}" -tags ${BUILD_TAGS} .

# Verify that FIPS crypto libs are accessible
RUN nm manager | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build rclone
#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS rclone-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG RCLONE_VERSION=v1.63.1
ARG RCLONE_GIT_HASH=bd1fbcae12f795f498c7ace6af9d9cc218102094

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/rclone/app

# Remove link flag that strips symbols so that we can verify crypto libs
RUN sed -i 's/--ldflags "-s /--ldflags "/g' Makefile

# Make sure the Rclone version tag matches the git hash we're expecting
RUN /bin/bash -c "[[ bd1fbcae12f795f498c7ace6af9d9cc218102094 == ${RCLONE_GIT_HASH} ]]"
RUN source $REMOTE_SOURCES_DIR/rclone/cachito.env && GOTAGS=${BUILD_TAGS} make rclone

# Verify that FIPS crypto libs are accessible
RUN nm rclone | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build restic
#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS restic-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG RESTIC_VERSION=v0.17.0
ARG RESTIC_GIT_HASH=277c8f5029a12bd882c2c1d2088f435caec67bb8

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/volsync/app/mover-restic
RUN /bin/bash -c "[[ 277c8f5029a12bd882c2c1d2088f435caec67bb8 == ${RESTIC_GIT_HASH} ]] && grep -q 277c8f5029a12bd882c2c1d2088f435caec67bb8 ./SOURCE_VERSIONS"

WORKDIR $REMOTE_SOURCES_DIR/volsync/app/mover-restic/restic

# Preserve symbols so that we can verify crypto libs
RUN sed -i 's/preserveSymbols := false/preserveSymbols := true/g' build.go
RUN source $REMOTE_SOURCES_DIR/restic/cachito.env && go run build.go --enable-cgo --tags ${BUILD_TAGS}

# Verify that FIPS crypto libs are accessible
RUN nm restic | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build syncthing
#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS syncthing-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG SYNCTHING_VERSION="v1.29.2"
ARG SYNCTHING_GIT_HASH="516f3e29e8cc7091ea6271715308caea0fcc0778"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/syncthing/app

RUN /bin/bash -c "[[ 516f3e29e8cc7091ea6271715308caea0fcc0778 == ${SYNCTHING_GIT_HASH} ]]"
RUN source $REMOTE_SOURCES_DIR/syncthing/cachito.env && go run build.go -no-upgrade -tags ${BUILD_TAGS}

# Verify that FIPS crypto libs are accessible
RUN nm bin/syncthing | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build diskrsync binary
#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS diskrsync-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG DISKRSYNC_VERSION="v1.3.0"
ARG DISKRSYNC_GIT_HASH="507805c4378495fc2267b77f6eab3d6bb318c86c"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/diskrsync/app

RUN /bin/bash -c "[[ 507805c4378495fc2267b77f6eab3d6bb318c86c == ${DISKRSYNC_GIT_HASH} ]]"
RUN source $REMOTE_SOURCES_DIR/diskrsync/cachito.env && GO111MODULE=on go build -a -o bin/diskrsync -tags ${BUILD_TAGS} ./diskrsync

# Verify that FIPS crypto libs are accessible
# RUN nm bin/diskrsync | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build diskrsync-tcp binary
#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS diskrsync-tcp-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG version_arg
ENV version="${version_arg}"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/volsync/app

RUN source $REMOTE_SOURCES_DIR/volsync/cachito.env && GO111MODULE=on go build -a -o diskrsync-tcp/diskrsync-tcp -ldflags "-X=main.volsyncVersion=${version}" -tags ${BUILD_TAGS} diskrsync-tcp/main.go

# Verify that FIPS crypto libs are accessible
RUN nm diskrsync-tcp/diskrsync-tcp | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Final container

#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.5-1741850109

WORKDIR /

RUN microdnf --refresh update -y && \
    microdnf --nodocs --setopt=install_weak_deps=0 install -y \
        acl             `# rclone - getfacl/setfacl` \
        openssh         `# rsync/ssh - ssh key generation in operator` \
        openssh-clients `# rsync/ssh - ssh client` \
        openssh-server  `# rsync/ssh - ssh server` \
        perl            `# rsync/ssh - rrsync script` \
        stunnel         `# rsync-tls` \
        openssl         `# syncthing - server certs` \
        vim-minimal     `# for mover debug` \
        tar             `# for mover debug` \
    && microdnf --setopt=install_weak_deps=0 install -y \
        `# docs are needed so rrsync gets installed for ssh variant` \
        rsync           `# rsync/ssh, rsync-tls - rsync, rrsync` \
    && microdnf clean all && \
    rm -rf /var/cache/yum


##### VolSync operator
COPY --from=manager-builder $REMOTE_SOURCES_DIR/volsync/app/manager /manager

##### rclone
COPY --from=rclone-builder $REMOTE_SOURCES_DIR/rclone/app/rclone /usr/local/bin/rclone
COPY --from=rclone-builder $REMOTE_SOURCES_DIR/volsync/app/mover-rclone/active.sh \
     /mover-rclone/
RUN chmod a+rx /mover-rclone/*.sh

##### restic
COPY --from=restic-builder $REMOTE_SOURCES_DIR/volsync/app/mover-restic/restic/restic  /usr/local/bin/restic
COPY --from=restic-builder $REMOTE_SOURCES_DIR/volsync/app/mover-restic/entry.sh \
     /mover-restic/
RUN chmod a+rx /mover-restic/*.sh

##### rsync (ssh)
COPY --from=manager-builder $REMOTE_SOURCES_DIR/volsync/app/mover-rsync/source.sh \
     $REMOTE_SOURCES_DIR/volsync/app/mover-rsync/destination.sh \
     $REMOTE_SOURCES_DIR/volsync/app/mover-rsync/destination-command.sh \
     /mover-rsync/
RUN chmod a+rx /mover-rsync/*.sh

RUN ln -s /keys/destination /etc/ssh/ssh_host_rsa_key && \
    ln -s /keys/destination.pub /etc/ssh/ssh_host_rsa_key.pub && \
    install /usr/share/doc/rsync/support/rrsync /usr/local/bin && \
    \
    SSHD_CONFIG="/etc/ssh/sshd_config" && \
    sed -ir 's|^[#\s]*\(.*/etc/ssh/ssh_host_ecdsa_key\)$|#\1|' "$SSHD_CONFIG" && \
    sed -ir 's|^[#\s]*\(.*/etc/ssh/ssh_host_ed25519_key\)$|#\1|' "$SSHD_CONFIG" && \
    sed -ir 's|^[#\s]*\(PasswordAuthentication\)\s.*$|\1 no|' "$SSHD_CONFIG" && \
    sed -ir 's|^[#\s]*\(GSSAPIAuthentication\)\s.*$|\1 no|' "$SSHD_CONFIG" && \
    sed -ir 's|^[#\s]*\(AllowTcpForwarding\)\s.*$|\1 no|' "$SSHD_CONFIG" && \
    sed -ir 's|^[#\s]*\(X11Forwarding\)\s.*$|\1 no|' "$SSHD_CONFIG" && \
    sed -ir 's|^[#\s]*\(PermitTunnel\)\s.*$|\1 no|' "$SSHD_CONFIG" && \
    sed -ir 's|^[#\s]*\(PidFile\)\s.*$|\1 /tmp/sshd.pid|' "$SSHD_CONFIG"

##### rsync-tls
COPY --from=manager-builder $REMOTE_SOURCES_DIR/volsync/app/mover-rsync-tls/client.sh \
     $REMOTE_SOURCES_DIR/volsync/app/mover-rsync-tls/server.sh \
     /mover-rsync-tls/
RUN chmod a+rx /mover-rsync-tls/*.sh

##### syncthing
COPY --from=syncthing-builder $REMOTE_SOURCES_DIR/syncthing/app/bin/syncthing /usr/local/bin/syncthing
ENV SYNCTHING_DATA_TRANSFERMODE="sendreceive"
COPY --from=syncthing-builder $REMOTE_SOURCES_DIR/volsync/app/mover-syncthing/config-template.xml \
     /mover-syncthing/
RUN chmod a+r /mover-syncthing/config-template.xml

COPY --from=syncthing-builder $REMOTE_SOURCES_DIR/volsync/app/mover-syncthing/config-template.xml \
     $REMOTE_SOURCES_DIR/volsync/app/mover-syncthing/stignore-template \
     $REMOTE_SOURCES_DIR/volsync/app/mover-syncthing/entry.sh \
     /mover-syncthing/
RUN chmod a+r /mover-syncthing/config-template.xml && \
    chmod a+r /mover-syncthing/stignore-template && \
    chmod a+rx /mover-syncthing/*.sh

##### diskrsync
COPY --from=diskrsync-builder $REMOTE_SOURCES_DIR/diskrsync/app/bin/diskrsync /usr/local/bin/diskrsync

##### diskrsync-tcp
COPY --from=diskrsync-tcp-builder $REMOTE_SOURCES_DIR/volsync/app/diskrsync-tcp/diskrsync-tcp /diskrsync-tcp

##### Set build metadata
ARG version_arg
ENV version="${version_arg}"

# uid/gid: nobody/nobody
USER 65534:65534

ENTRYPOINT ["/bin/bash"]

LABEL com.redhat.component="volsync-container" \
      name="rhacm2/volsync-rhel9" \
      version="v0.12.1" \
      summary="volsync" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="volsync" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="volsync"
