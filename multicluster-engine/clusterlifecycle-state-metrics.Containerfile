FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=clusterlifecycle-state-metrics
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default clusterlifecycle-state-metrics .

RUN go build -tags strictfipsruntime ./cmd/clusterlifecycle-state-metrics
RUN go test -covermode=atomic -coverpkg=github.com/stolostron/clusterlifecycle-state-metrics/pkg/... -c -tags testrunmain ./cmd/clusterlifecycle-state-metrics -o clusterlifecycle-state-metrics-coverage


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/clusterlifecycle-state-metrics \
    USER_UID=1001 \
    USER_NAME=clusterlifecycle-state-metrics

COPY --from=builder /opt/app-root/src/clusterlifecycle-state-metrics ${OPERATOR}
COPY --from=builder /opt/app-root/src/clusterlifecycle-state-metrics-coverage ${OPERATOR}-coverage
COPY --from=builder \
    /opt/app-root/src/build/coverage-entrypoint-func.sh \
    /usr/local/bin/coverage-entrypoint-func.sh
COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin

RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL summary="clusterlifecycle-state-metrics" \
      io.k8s.display-name="clusterlifecycle-state-metrics" \
      maintainer="['maintainers@okd.io']" \
      description="clusterlifecycle-state-metrics"
