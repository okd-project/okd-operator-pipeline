# Upstream source file for building is Dockerfile.ocp in
#       https://github.com/stolostron/grafana
FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/grafana/app

COPY Dockerfile.ocp.cached Dockerfile.ocp.cached
RUN /dockerfile-drifter.sh Dockerfile.ocp Dockerfile.ocp.cached
#COPY Dockerfile.ubuntu.cached Dockerfile.ubuntu.cached
#RUN /dockerfile-drifter.sh Dockerfile.ubuntu Dockerfile.ubuntu.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder
# #@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.22)
# FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.22.12-202503201431.g058f2aa.el9 AS builder

ENV COMPONENT_VERSION=2.13.3
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/grafana/app

# Apply custom patches
RUN dnf -y install git
RUN source $REMOTE_SOURCES_DIR/grafana/cachito.env && git apply ./stolostron-patches/*

RUN source $REMOTE_SOURCES_DIR/grafana/cachito.env && go run -tags strictfipsruntime build.go build

# Need to copy the generated binaries to a non-platform specific location to handle
# s390x builds for example
RUN cp bin/linux-$(go env GOARCH)/grafana* \
       /usr/bin/

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9/ubi:latest)
FROM registry.redhat.io/ubi9/ubi:9.6-1745489786

ARG GF_UID="472"
ARG GF_GID="472"

ENV PATH=/usr/share/grafana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

WORKDIR $GF_PATHS_HOME

RUN dnf -y update && dnf clean all

COPY --from=builder $REMOTE_SOURCES_DIR/grafana/app/conf ./conf

RUN mkdir -p "$GF_PATHS_HOME/.aws" && \
    # addgroup -S -g $GF_GID grafana && \
    # adduser -S -u $GF_UID -G grafana grafana && \
    # Note: the openshift base image does not include the addgroup and adduser commands so we have to use useradd/groupadd
    groupadd --system -g $GF_GID grafana && \
    useradd --system -u $GF_UID -g grafana grafana && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
             "$GF_PATHS_PROVISIONING/dashboards" \
             "$GF_PATHS_PROVISIONING/notifiers" \
             "$GF_PATHS_LOGS" \
             "$GF_PATHS_PLUGINS" \
             "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING" && \
    chmod -R 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING"

COPY --from=builder /usr/bin/grafana* ./bin/
COPY --from=builder $REMOTE_SOURCES_DIR/grafana/app/public ./public
COPY --from=builder $REMOTE_SOURCES_DIR/grafana/app/tools ./tools

EXPOSE 3000

COPY --from=builder $REMOTE_SOURCES_DIR/grafana/app/packaging/docker/run.sh /run.sh

USER grafana
ENTRYPOINT ["/run.sh"]

LABEL com.redhat.component="acm-grafana-container" \
      name="rhacm2/acm-grafana-rhel9" \
      version="v2.13.3" \
      upstream-ref="ee44f9d08860a49bddf6a3e537b3b04ed28c7655" \
      upstream-url="git@github.com:stolostron/grafana.git" \
      summary="Grafana is an open-source, general purpose dashboard and graph composer" \
      io.openshift.expose-services="" \
      io.openshift.tags="openshift rhacm observability" \
      io.k8s.display-name="Grafana" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="Grafana is an open-source, general purpose dashboard and graph composer; this image is built for ACM observability"

# 20241101

