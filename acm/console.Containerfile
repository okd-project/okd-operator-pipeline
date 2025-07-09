FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS builder

ENV COMPONENT_NAME=console
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "

COPY --chown=default ./console .

USER root
ENV NPM_CONFIG_NODEDIR=/usr

# Running installs concurrently fails on aarch64
RUN npm ci --omit=optional  --unsafe-perm --ignore-scripts
RUN cd backend && npm ci --omit=optional  --unsafe-perm
RUN cd frontend && npm ci --legacy-peer-deps --unsafe-perm
RUN npm run build:backend
RUN cd frontend && npm run build:plugin:acm

# Remove build-time dependencies before packaging
RUN cd backend && npm ci --omit=optional --only=production --unsafe-perm


FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-nodejs-parent:v2.10.0_20-55

RUN dnf -y update && dnf clean all

WORKDIR /app

ENV NODE_ENV production
COPY --from=builder $REMOTE_SOURCE_DIR/app/backend/node_modules ./node_modules
COPY --from=builder $REMOTE_SOURCE_DIR/app/backend/backend.mjs ./
COPY --from=builder $REMOTE_SOURCE_DIR/app/frontend/plugins/acm/dist ./public/plugin

USER 1001
CMD ["node", "backend.mjs"]

LABEL com.redhat.component="console-container" \
      name="rhacm2/console-rhel9" \
      version="v2.13.3" \
      upstream-ref="700b65c65f7422b5cfe9ccd08a5bcc49f1fac08a" \
      upstream-url="git@github.com:stolostron/console.git" \
      summary="console" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="console" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="console"
