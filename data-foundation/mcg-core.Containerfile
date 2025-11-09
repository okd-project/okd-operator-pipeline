##############################################################
# Target: noobaa_npm
#   Title: building the noobaa npm (using cachito's npm)
#
# This Target will build the node_modules.
##############################################################
ARG IMG_CLI
FROM $IMG_CLI as oc_builder

RUN oc version

FROM quay.io/centos/centos:stream9 as noobaa_builder

RUN dnf group install -y "Development Tools" && \
    dnf install dnf-plugins-core -y && \
    dnf config-manager --set-enabled crb && \
    dnf module enable -y nodejs:22 && \
    dnf install -y \
    python3 \
    python-unversioned-command \
    nodejs-devel \
    npm \
    boost-devel \
    libcap-devel \
    nasm && \
    dnf clean all

ENV NPM_CONFIG_NODEDIR=/usr

WORKDIR /opt/app-root/src

COPY ./noobaa-core .

RUN npm --nodedir=/usr rebuild --omit=dev && \
    npm --nodedir=/usr install --omit=dev --python=/usr/bin/python3 && \
    GYP_DEFINES=BUILD_S3SELECT=1 npm --nodedir=/usr run build:native

RUN mkdir -p /noobaa_init_files

##############################################################
# Target: noobaa_tarball
#   Title: Getting noobaa into a tar. We are doing it in
#	   different target so it will be clean
##############################################################

FROM registry.access.redhat.com/ubi9/ubi:latest as noobaa_tarball

RUN dnf module enable -y nodejs:22 && \
    dnf install -y nodejs-devel \
    patch  && \
    dnf clean all

WORKDIR /src

COPY ./noobaa-core .

COPY --from=noobaa_builder /opt/app-root/src/node_modules/ ./node_modules/
COPY --from=noobaa_builder /noobaa_init_files/ /noobaa_init_files/
COPY --from=noobaa_builder /opt/app-root/src/build/Release/ ./build/Release/
COPY config-local.js .

RUN node -e "let pkg=require('./package.json'); delete pkg.devDependencies; require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2));"


RUN tar \
    --transform='s:^:noobaa-core/:' \
    --exclude='src/native/aws-cpp-sdk' \
    --exclude='src/native/third_party' \
    -czf noobaa-NVA.tar.gz \
    LICENSE \
    package.json \
    platform_restrictions.json \
    config.js \
    config-local.js \
    .nvmrc \
    src/ \
    build/Release/ \
    node_modules/

##############################################################################

FROM quay.io/centos/centos:stream9

ENV container docker
ENV PORT 8080
ENV SSL_PORT 8443
ENV ENDPOINT_PORT 6001
ENV ENDPOINT_SSL_PORT 6443
ENV WEB_NODE_OPTIONS ''
ENV BG_NODE_OPTIONS ''
ENV HOSTED_AGENTS_NODE_OPTIONS ''
ENV ENDPOINT_NODE_OPTIONS ''

RUN dnf module enable -y nodejs:22 && \
    dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf install epel-release -y && \
    dnf install -y \
    bash \
    lsof \
    openssl \
    rsyslog \
    strace \
    wget \
    curl-minimal \
    nc \
    vim \
    less \
    bash-completion \
    nodejs \
    npm \
    boost \
    supervisor \
    jemalloc \
    cronie && \
    dnf clean all

RUN ln -sf $(which node) /usr/local/bin/node && \
    ln -sf $(which npm) /usr/local/bin/npm && \
    ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

RUN mkdir -p /data/ && \
    mkdir -p /log

COPY --from=noobaa_tarball /src/src/deploy/NVA_build/supervisord.orig ./src/deploy/NVA_build/
COPY --from=noobaa_tarball /src/src/deploy/NVA_build/supervisord.orig /tmp/supervisord
COPY --from=noobaa_tarball /src/src/deploy/NVA_build/supervisorctl.bash_completion /etc/bash_completion.d/supervisorctl
COPY --from=noobaa_tarball /src/src/deploy/NVA_build/rsyslog.conf /etc/rsyslog.conf
COPY --from=noobaa_tarball /src/src/deploy/NVA_build/noobaa_syslog.conf /etc/rsyslog.d/
COPY --from=noobaa_tarball /src/src/deploy/NVA_build/noobaa-logrotate /etc/logrotate.d/
COPY --from=noobaa_tarball /src/src/deploy/NVA_build/noobaa_init.sh /noobaa_init_files/

COPY --from=noobaa_tarball /src/src/deploy/NVA_build/setup_platform.sh /usr/bin/setup_platform.sh
RUN /usr/bin/setup_platform.sh

RUN chmod 775 /noobaa_init_files && \
    chgrp -R 0 /noobaa_init_files/ && \
    chmod -R g=u /noobaa_init_files/

RUN mkdir -m 777 /root/node_modules

COPY --from=noobaa_tarball /src/noobaa-NVA.tar.gz /tmp/
RUN cd /root/node_modules && \
    tar -xzf /tmp/noobaa-NVA.tar.gz && \
    chgrp -R 0 /root/node_modules && \
    chmod -R 775 /root/node_modules

# Copy oc binary and create kubectl symlink
COPY --from=oc_builder /usr/bin/oc /usr/bin/oc
RUN ln -s /usr/bin/oc /usr/bin/kubectl

###############
# PORTS SETUP #
###############
EXPOSE 60100
EXPOSE 80
EXPOSE 443
EXPOSE 8080
EXPOSE 8443
EXPOSE 8444
EXPOSE 27000
EXPOSE 26050

ENV LD_PRELOAD /usr/lib64/libjemalloc.so.2

###############
# EXEC SETUP #
###############
# run as non root user that belongs to root
RUN useradd -u 10001 -g 0 -m -d /home/noob -s /bin/bash noob
USER 10001:0

CMD ["/usr/bin/supervisord", "start"]

LABEL io.k8s.display-name="MultiCloud Object Gateway Core based on UBI 9" \
    io.k8s.description="MultiCloud Object Gateway Core Container based on UBI 9 Image" \
    summary="Provides the latest MultiCloud Object Gateway Core container for OKD Data Foundation" \
    description="OKD Data Foundation MultiCloud Object Gateway Core container"