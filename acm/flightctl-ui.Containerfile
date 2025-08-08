FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS ui-build

ARG VERSION

ENV COMPONENT_NAME=acm-flightctl-ui
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "

COPY flightctl-ui .

USER root
RUN microdnf install -y rsync

ENV NPM_CONFIG_NODEDIR=/usr
ENV NODE_OPTIONS='--max-old-space-size=8192'

# RUN npm ci
RUN npm ci --omit=optional  --unsafe-perm --ignore-scripts
RUN npm run build

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV COMPONENT_NAME=acm-flightctl-ui
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GO111MODULE=on
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default flightctl-ui .
WORKDIR $HOME/proxy
USER 0
RUN go build


FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest

COPY --from=ui-build /opt/app-root/src/apps/standalone/dist /app/proxy/dist
COPY --from=builder /opt/app-root/src/proxy/flightctl-ui /app/proxy

WORKDIR /app/proxy
EXPOSE 8080
CMD ./flightctl-ui


LABEL summary="acm-flightctl-ui" \
      io.k8s.display-name="acm-flightctl-ui" \
      maintainer="['maintainers@okd.io']" \
      description="acm-flightctl-ui"
