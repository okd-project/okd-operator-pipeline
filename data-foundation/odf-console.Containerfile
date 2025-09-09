FROM registry.access.redhat.com/ubi9/nodejs-20 AS builder

ARG CI_VERSION

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

COPY --chown=default ./odf-console ./odf-console
COPY --chown=default ./odf-console-compatibility ./odf-console-compatibility

# Set NPM Environment
ENV NPM_CONFIG_NODEDIR=/usr

ENV CYPRESS_INSTALL_BINARY=0
ENV GECKODRIVER_SKIP_DOWNLOAD=true
ENV SKIP_SASS_BINARY_DOWNLOAD_FOR_CI=true
ENV CHROMEDRIVER_SKIP_DOWNLOAD=true
ENV PLUGIN_VERSION="${CI_VERSION}"

WORKDIR /opt/app-root/src/odf-console
RUN yarn install --prod=true --frozen-lockfile
RUN yarn build

# Update the version for compatibility build
ENV PLUGIN_VERSION="${CI_VERSION}-compatibility"
WORKDIR /opt/app-root/src/odf-console-compatibility
RUN yarn install --prod=true --frozen-lockfile
RUN yarn build


FROM registry.access.redhat.com/ubi9/nginx-120

COPY --from=builder /opt/app-root/src/odf-console/plugins/odf/dist .
COPY --from=builder /opt/app-root/src/odf-console-compatibility/plugins/odf/dist ./compatibility
CMD /usr/libexec/s2i/run

USER root
RUN dnf --exclude 'nginx*' --disablerepo 'rhel-8-*' update -y && \
     dnf clean all
USER default

LABEL description="OKD Data Foundation Console container" \
    summary="Provides the latest console for OKD Data Foundation." \
    io.k8s.display-name="ODF Console"