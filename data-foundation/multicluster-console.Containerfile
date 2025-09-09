FROM registry.access.redhat.com/ubi9/nodejs-20 AS builder

ARG VERSION

USER root
# Required for build
#   * make gcc-c++ for node-gyp which
#   * python3 for react-scripts
#   * nodejs-devel
#
RUN dnf install -y python3 \
        nodejs-devel \
        make \
        gcc-c++ && \
        dnf clean all && \
    npm install --global yarn
USER default

COPY --chown=default ./odf-console .

# Set NPM Environment
ENV NPM_CONFIG_NODEDIR=/usr

ENV CYPRESS_INSTALL_BINARY=0
ENV GECKODRIVER_SKIP_DOWNLOAD=true
ENV SKIP_SASS_BINARY_DOWNLOAD_FOR_CI=true
ENV CHROMEDRIVER_SKIP_DOWNLOAD=true
ENV PLUGIN_VERSION="${VERSION}"

RUN yarn install --prod=true --frozen-lockfile
RUN yarn build-mco

FROM registry.access.redhat.com/ubi9/nginx-120

COPY --from=builder /opt/app-root/src/default.conf "${NGINX_CONFIGURATION_PATH}"
COPY --from=builder /opt/app-root/src/plugins/mco/dist .
CMD /usr/libexec/s2i/run

USER root
RUN dnf --exclude 'nginx*' --disablerepo 'rhel-8-*' update -y && \
     dnf clean all
USER default

LABEL description="OKD Data Foundation Multicluster Console container" \
    summary="Provides the latest console for OKD Data Foundation Multicluster Orchestrator." \
    io.k8s.display-name="ODF Multicluster Console"
