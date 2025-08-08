FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS builder

ARG CI_VERSION

ENV COMPONENT_NAME=multicluster-engine-console-mce
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "

COPY console .

USER root
ENV NPM_CONFIG_NODEDIR=/usr

# Running installs concurrently fails on aarch64
RUN npm ci --omit=optional  --unsafe-perm --ignore-scripts
RUN cd backend && npm ci --omit=optional  --unsafe-perm
RUN cd frontend && npm ci --legacy-peer-deps --unsafe-perm
RUN npm run build:backend
RUN cd frontend && npm run build:plugin:mce

# Remove build-time dependencies before packaging
RUN cd backend && npm ci --omit=optional --only=production --unsafe-perm


FROM registry.access.redhat.com/ubi9/nodejs-20:latest

WORKDIR /app
ENV NODE_ENV production
COPY --from=builder /opt/app-root/src/backend/node_modules ./node_modules
COPY --from=builder /opt/app-root/src/backend/backend.mjs ./
COPY --from=builder /opt/app-root/src/frontend/plugins/mce/dist ./public/plugin
USER 1001
CMD ["node", "backend.mjs"]

LABEL summary="multicluster-engine-console-mce" \
      io.k8s.display-name="multicluster-engine-console-mce" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-console-mce"
