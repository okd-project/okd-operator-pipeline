ARG VERSION

######################################################################
# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS manager-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG CI_VERSION
ENV version="$CI_VERSION"

COPY --chown=default volsync/volsync .

RUN GO111MODULE=on go build -a -o manager -ldflags "-X=main.volsyncVersion=${version}" -tags ${BUILD_TAGS} ./cmd/...

# Verify that FIPS crypto libs are accessible
RUN nm manager | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build rclone
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS rclone-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1

ARG RCLONE_VERSION=v1.63.1
ARG RCLONE_GIT_HASH=bd1fbcae12f795f498c7ace6af9d9cc218102094

COPY --chown=default volsync/rclone .

# Remove link flag that strips symbols so that we can verify crypto libs
RUN sed -i 's/--ldflags "-s /--ldflags "/g' Makefile

RUN GOTAGS=${BUILD_TAGS} make rclone

# Verify that FIPS crypto libs are accessible
RUN nm rclone | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build restic
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS restic-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1

ARG RESTIC_VERSION=v0.17.0
ARG RESTIC_GIT_HASH=277c8f5029a12bd882c2c1d2088f435caec67bb8

COPY --chown=default volsync/volsync .
WORKDIR $HOME/mover-restic

WORKDIR $HOME/mover-restic/restic

# Preserve symbols so that we can verify crypto libs
RUN sed -i 's/preserveSymbols := false/preserveSymbols := true/g' build.go
RUN go run build.go --enable-cgo --tags ${BUILD_TAGS}

# Verify that FIPS crypto libs are accessible
RUN nm restic | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build syncthing
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS syncthing-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1

ARG SYNCTHING_VERSION="v1.29.2"
ARG SYNCTHING_GIT_HASH="516f3e29e8cc7091ea6271715308caea0fcc0778"

COPY --chown=default volsync/syncthing .

RUN go run build.go -no-upgrade -tags ${BUILD_TAGS}

# Verify that FIPS crypto libs are accessible
RUN nm bin/syncthing | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build diskrsync binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS diskrsync-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1

ARG DISKRSYNC_VERSION="v1.3.0"
ARG DISKRSYNC_GIT_HASH="507805c4378495fc2267b77f6eab3d6bb318c86c"

COPY --chown=default volsync/diskrsync .

RUN GO111MODULE=on go build -a -o bin/diskrsync -tags ${BUILD_TAGS} ./diskrsync

# Verify that FIPS crypto libs are accessible
# RUN nm bin/diskrsync | grep -q "goboringcrypto\|golang-fips"


######################################################################
# Build diskrsync-tcp binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS diskrsync-tcp-builder

ENV GOFLAGS='-p=4 -mod=readonly'
ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

ARG VERSION
ENV version="$VERSION"

COPY --chown=default volsync/volsync .

RUN GO111MODULE=on go build -a -o diskrsync-tcp/diskrsync-tcp -ldflags "-X=main.volsyncVersion=${version}" -tags ${BUILD_TAGS} diskrsync-tcp/main.go

# Verify that FIPS crypto libs are accessible
RUN nm diskrsync-tcp/diskrsync-tcp | grep -q "goboringcrypto\|golang-fips"

######################################################################
# Final container

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /


    rm -rf /var/cache/yum


ENV REMOTE_SOURCES_DIR=/opt/app-root/src

##### VolSync operator
COPY --from=manager-builder $REMOTE_SOURCES_DIR/manager /manager

##### rclone
COPY --from=rclone-builder $REMOTE_SOURCES_DIR/rclone /usr/local/bin/rclone
COPY --from=manager-builder $REMOTE_SOURCES_DIR/mover-rclone/active.sh \
     /mover-rclone/
RUN chmod a+rx /mover-rclone/*.sh

##### restic
COPY --from=restic-builder $REMOTE_SOURCES_DIR/mover-restic/restic/restic  /usr/local/bin/restic
COPY --from=restic-builder $REMOTE_SOURCES_DIR/mover-restic/entry.sh \
     /mover-restic/
RUN chmod a+rx /mover-restic/*.sh

##### rsync (ssh)
COPY --from=manager-builder $REMOTE_SOURCES_DIR/mover-rsync/source.sh \
     $REMOTE_SOURCES_DIR/mover-rsync/destination.sh \
     $REMOTE_SOURCES_DIR/mover-rsync/destination-command.sh \
     /mover-rsync/
RUN chmod a+rx /mover-rsync/*.sh


    sed -ir 's|^[#\s]*\(PidFile\)\s.*$|\1 /tmp/sshd.pid|' "$SSHD_CONFIG"

##### rsync-tls
COPY --from=manager-builder $REMOTE_SOURCES_DIR/mover-rsync-tls/client.sh \
     $REMOTE_SOURCES_DIR/mover-rsync-tls/server.sh \
     /mover-rsync-tls/
RUN chmod a+rx /mover-rsync-tls/*.sh

##### syncthing
COPY --from=syncthing-builder $REMOTE_SOURCES_DIR/bin/syncthing /usr/local/bin/syncthing
ENV SYNCTHING_DATA_TRANSFERMODE="sendreceive"
COPY --from=manager-builder $REMOTE_SOURCES_DIR/mover-syncthing/config-template.xml \
     /mover-syncthing/
RUN chmod a+r /mover-syncthing/config-template.xml

COPY --from=manager-builder $REMOTE_SOURCES_DIR/mover-syncthing/config-template.xml \
     $REMOTE_SOURCES_DIR/mover-syncthing/stignore-template \
     $REMOTE_SOURCES_DIR/mover-syncthing/entry.sh \
     /mover-syncthing/
RUN chmod a+r /mover-syncthing/config-template.xml && \
    chmod a+r /mover-syncthing/stignore-template && \
    chmod a+rx /mover-syncthing/*.sh

##### diskrsync
COPY --from=diskrsync-builder $REMOTE_SOURCES_DIR/bin/diskrsync /usr/local/bin/diskrsync

##### diskrsync-tcp
COPY --from=diskrsync-tcp-builder $REMOTE_SOURCES_DIR/diskrsync-tcp/diskrsync-tcp /diskrsync-tcp

##### Set build metadata
ARG VERSION
ENV version="$VERSION"

# uid/gid: nobody/nobody
USER 65534:65534

ENTRYPOINT ["/bin/bash"]

LABEL summary="volsync" \
      io.k8s.display-name="volsync" \
      io.k8s.description="volsync" \
      maintainer="maintainers@okd.io" \
      description="volsync"
