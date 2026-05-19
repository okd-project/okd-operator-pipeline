# Build che-machine-exec for UBI8 user containers
FROM registry.access.redhat.com/ubi8/go-toolset:1.25 AS ubi8-machineexec-builder
ENV GOPATH=/go/
ENV CGO_ENABLED=1
USER root
COPY ./che-machine-exec /che-machine-exec
WORKDIR /che-machine-exec
RUN GOOS=linux go build -mod=vendor -a -ldflags '-w -s' -a -installsuffix cgo -o che-machine-exec . \
    && mkdir -p /rootfs/go/bin \
    && cp /che-machine-exec/che-machine-exec /rootfs/go/bin

# Build che-machine-exec for UBI9 user containers
FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS ubi9-machineexec-builder
ENV GOPATH=/go/
ENV CGO_ENABLED=1
USER root
COPY ./che-machine-exec /che-machine-exec
WORKDIR /che-machine-exec
RUN GOOS=linux go build -mod=vendor -a -ldflags '-w -s' -a -installsuffix cgo -o che-machine-exec . \
    && mkdir -p /rootfs/go/bin \
    && cp /che-machine-exec/che-machine-exec /rootfs/go/bin

# Build VS Code (checode) on CentOS Stream 9 — works for both UBI8 and UBI9
# user containers under OKD (which targets RHEL9/CS9).  The separate UBI8
# glibc-2.28 build is skipped here; both ubi8 and ubi9 paths in the final
# image will use this single build.
FROM quay.io/centos/centos:stream9 AS checode-builder

USER root

ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

COPY ./che-code /che-code
WORKDIR /che-code/code

RUN dnf module enable nodejs:22 -y && \
    dnf install -y --enablerepo=crb \
    nodejs nodejs-devel npm libsecret-devel libsecret krb5-devel make gcc gcc-c++ \
    git git-core-doc openssh ca-certificates python3 \
    less libX11-devel libxkbcommon libxkbfile libxkbfile-devel \
    bash tar gzip rsync patch jq && \
    dnf clean all

RUN cd /che-code/branding && ./branding.sh

RUN git init .

RUN NODE_ARCH=$(echo "console.log(process.arch)" | node) && \
    NODE_VERSION=$(cat /che-code/code/remote/.npmrc | grep target | cut -d '=' -f 2 | tr -d '"') && \
    mkdir -p /che-code/code/.build/node/v${NODE_VERSION}/linux-${NODE_ARCH} && \
    cp /usr/bin/node /che-code/code/.build/node/v${NODE_VERSION}/linux-${NODE_ARCH}/node && \
    mkdir -p /checode/ld_libs && \
    find /usr/lib64 -name 'libnode.so*' -exec cp -P -t /checode/ld_libs/ {} + && \
    find /usr/lib64 -name 'libz.so*' -exec cp -P -t /checode/ld_libs/ {} +

RUN npm install

RUN export NODE_ARCH=$(echo "console.log(process.arch)" | node) && \
    NODE_OPTIONS="--max-old-space-size=8192" ./node_modules/.bin/gulp vscode-reh-web-linux-${NODE_ARCH}-min -LLLL && \
    cp -r ../vscode-reh-web-linux-${NODE_ARCH}/. /checode

RUN chmod a+x /checode/out/server-main.js && \
    chgrp -R 0 /checode && chmod -R g+rwX /checode

WORKDIR /che-code/launcher/
RUN npm install && \
    mkdir /checode/launcher && \
    cp -r out/src/*.js /checode/launcher && \
    chgrp -R 0 /checode && chmod -R g+rwX /checode

# Final runtime image
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:9.7

USER root

RUN microdnf install -y openssh-clients bash tar gzip rsync && microdnf clean all

# Copy checode for ubi8-based user containers
RUN mkdir -p /checode-linux-libc/ubi8
COPY --from=checode-builder --chown=0:0 /checode/ /checode-linux-libc/ubi8/
COPY --from=ubi8-machineexec-builder --chown=0:0 /rootfs/go/bin/che-machine-exec /checode-linux-libc/ubi8/machine-exec

# Copy checode for ubi9-based user containers
RUN mkdir -p /checode-linux-libc/ubi9
COPY --from=checode-builder --chown=0:0 /checode/ /checode-linux-libc/ubi9/
COPY --from=ubi9-machineexec-builder --chown=0:0 /rootfs/go/bin/che-machine-exec /checode-linux-libc/ubi9/machine-exec

COPY ./che-code/build/scripts/entrypoint.sh /entrypoint.sh
COPY ./che-code/build/scripts/entrypoint-volume.sh /entrypoint-volume.sh

RUN chmod a+x /entrypoint.sh /entrypoint-volume.sh && \
    chgrp -R 0 /checode-linux-libc && chmod -R g+rwX /checode-linux-libc

USER 10001

ENTRYPOINT ["/entrypoint.sh"]
