FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS ui-build

ARG CI_VERSION

ENV COMPONENT_NAME=acm-flightctl-ocp-ui
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "

COPY flightctl-ui .

USER root
RUN microdnf install -y rsync

ENV NPM_CONFIG_NODEDIR=/usr
ENV NODE_OPTIONS='--max-old-space-size=8192'

#RUN npm ci
RUN npm ci --omit=optional  --unsafe-perm --ignore-scripts
RUN npm run build:ocp

RUN ls -la $HOME/apps/ocp-plugin/dist


FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV COMPONENT_NAME=acm-flightctl-ocp-ui
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GO111MODULE=on
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default flightctl-ui .

WORKDIR $HOME/proxy
RUN go build


FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest

COPY --from=ui-build /opt/app-root/src/apps/ocp-plugin/dist /app/proxy/dist
COPY --from=builder /opt/app-root/src/proxy/flightctl-ui /app/proxy

WORKDIR /app/proxy
EXPOSE 8080
CMD ./flightctl-ui

LABEL summary="acm-flightctl-ocp-ui" \
      io.k8s.display-name="acm-flightctl-ocp-ui" \
      maintainer="['maintainers@okd.io']" \
      description="acm-flightctl-ocp-ui"
