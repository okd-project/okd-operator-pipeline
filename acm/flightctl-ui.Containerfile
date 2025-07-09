FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/flightctl-ui/app

COPY Containerfile.cached Containerfile.cached
RUN /dockerfile-drifter.sh Containerfile Containerfile.cached


# #@follow_tag(registry.redhat.io/ubi9/nodejs-20-minimal:latest)
FROM registry.redhat.io/ubi9/nodejs-20-minimal:1-63.1726695170 AS ui-build

ENV COMPONENT_NAME=acm-flightctl-ui
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/flightctl-ui/app

USER root
RUN microdnf install -y rsync

ENV NPM_CONFIG_NODEDIR=/usr
ENV NODE_OPTIONS='--max-old-space-size=8192'

# RUN npm ci
RUN npm ci --omit=optional  --unsafe-perm --ignore-scripts
RUN npm run build



#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV COMPONENT_NAME=acm-flightctl-ui
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GO111MODULE=on
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"
# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/flightctl-ui/app/proxy
USER 0
RUN source $REMOTE_SOURCES_DIR/flightctl-ui/cachito.env && go build



# #@follow_tag(registry.redhat.io/ubi9-minimal:latest)
# FROM registry.redhat.io/ubi9-minimal:9.5-1736404155

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-nodejs-parent:rhel_9_nodejs_20)
FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-nodejs-parent:v2.10.0_20-55

RUN dnf -y update && dnf clean all

COPY --from=ui-build $REMOTE_SOURCES_DIR/flightctl-ui/app/apps/standalone/dist /app/proxy/dist
COPY --from=builder $REMOTE_SOURCES_DIR/flightctl-ui/app/proxy/flightctl-ui /app/proxy

WORKDIR /app/proxy
EXPOSE 8080
CMD ./flightctl-ui


LABEL com.redhat.component="acm-flightctl-ui-container" \
      name="rhacm2/acm-flightctl-ui-rhel9" \
      version="v2.13.3" \
      upstream-ref="0c56e00e3798c89742dce8744de79ecfe60d8f6f" \
      upstream-url="git@github.com:flightctl/flightctl-ui.git" \
      summary="acm-flightctl-ui" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="acm-flightctl-ui" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="acm-flightctl-ui"

# 20220831
