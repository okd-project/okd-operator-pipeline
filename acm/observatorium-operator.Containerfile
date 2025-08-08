ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ENV COMPONENT_NAME=observatorium-operator
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default observatorium-operator .

WORKDIR $HOME/locutus

RUN GO111MODULE="on" go build -tags strictfipsruntime


FROM registry.access.redhat.com/ubi9/ubi:latest

WORKDIR /
ENV REMOTE_SOURCES_DIR=/opt/app-root/src
COPY --from=builder $REMOTE_SOURCES_DIR/locutus/locutus /locutus
COPY --from=builder $REMOTE_SOURCES_DIR/jsonnet /
COPY --from=builder $REMOTE_SOURCES_DIR/jsonnet/vendor/ /vendor/
COPY --from=builder $REMOTE_SOURCES_DIR/jsonnet/vendor/github.com/observatorium/observatorium/configuration/components/ /components/
RUN chgrp -R 0 /vendor && chmod -R g=u /vendor
RUN chgrp -R 0 /components && chmod -R g=u /components

ENTRYPOINT ["/locutus", "--renderer=jsonnet", "--renderer.jsonnet.entrypoint=main.jsonnet", "--trigger=resource", "--trigger.resource.config=config.yaml"]

LABEL summary="observatorium-operator" \
      io.k8s.display-name="observatorium-operator" \
      io.k8s.description="observatorium-operator" \
      maintainer="maintainers@okd.io" \
      description="observatorium-operator"
