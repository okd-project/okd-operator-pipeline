FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV COMPONENT_NAME=multicluster-observability-operator
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicluster-observability-operator .

RUN GOFLAGS="-p=4" go build -tags strictfipsruntime -a -installsuffix cgo -v -o bin/manager operators/multiclusterobservability/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/mco-operator \
    USER_UID=1001 \
    USER_NAME=mco

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

# install templates
COPY --from=builder $REMOTE_SOURCE_DIR/operators/multiclusterobservability/manifests /usr/local/manifests

# install the prestop script
COPY --from=builder $REMOTE_SOURCE_DIR/operators/multiclusterobservability/prestop.sh /usr/local/bin/prestop.sh

# install operator binary
COPY --from=builder $REMOTE_SOURCE_DIR/bin/manager ${OPERATOR}

USER ${USER_UID}
ENTRYPOINT ["/usr/local/bin/mco-operator"]

LABEL summary="multicluster-observability-operator" \
      io.k8s.display-name="multicluster-observability-operator" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-observability-operator"
