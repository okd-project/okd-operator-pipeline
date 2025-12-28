ARG OCP_SHORT

FROM registry.access.redhat.com/ubi9/nodejs-22:latest AS build

# Install yarn
RUN npm install -g yarn

# Copy app source
COPY --chown=default . .

RUN yarn install --frozen-lockfile && yarn build

# Web server container
FROM registry.ci.openshift.org/origin/scos-$OCP_SHORT:base-stream9

RUN INSTALL_PKGS="nginx" && \
    dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*' && \
    chown -R 1001:0 /var/lib/nginx /var/log/nginx /run && \
    chmod -R ug+rwX /var/lib/nginx /var/log/nginx /run

# Use non-root user
USER 1001

COPY --from=build /opt/app-root/src/dist /opt/app-root/src

# Run the server
CMD nginx -g "daemon off;"
