FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV COMPONENT_VERSION=$VERSION
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default acm/grafana acm/grafana
COPY --chown=default .git/ .git/

WORKDIR $HOME/acm/grafana

RUN git apply ./stolostron-patches/*

RUN go run -tags strictfipsruntime build.go build

# Need to copy the generated binaries to a non-platform specific location to handle
# s390x builds for example
RUN mkdir /tmp/bin && \
    cp bin/linux-$(go env GOARCH)/grafana* /tmp/bin/

FROM registry.access.redhat.com/ubi9/ubi:latest

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

ENV REMOTE_SOURCES_DIR="/opt/app-root/src/acm/grafana"

COPY --from=builder $REMOTE_SOURCES_DIR/conf ./conf

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

COPY --from=builder /tmp/bin/grafana* ./bin/
COPY --from=builder $REMOTE_SOURCES_DIR/public ./public
COPY --from=builder $REMOTE_SOURCES_DIR/tools ./tools

EXPOSE 3000

COPY --from=builder $REMOTE_SOURCES_DIR/packaging/docker/run.sh /run.sh

USER grafana
ENTRYPOINT ["/run.sh"]

LABEL summary="Grafana is an open-source, general purpose dashboard and graph composer" \
      io.k8s.display-name="Grafana" \
      maintainer="['maintainers@okd.io']" \
      description="Grafana is an open-source, general purpose dashboard and graph composer; this image is built for ACM observability"

