FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=endpoint-monitoring-operator
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicluster-observability-operator/ .

RUN GOFLAGS="-p=4" go build -tags strictfipsruntime -a -installsuffix cgo -o build/_output/bin/endpoint-monitoring-operator operators/endpointmetrics/main.go


FROM registry.access.redhat.com/ubi9-minimal:latest

ENV OPERATOR=/usr/local/bin/endpoint-monitoring-operator \
    USER_UID=1001 \
    USER_NAME=endpoint-monitoring-operator

RUN microdnf update -y && microdnf clean all

COPY --from=builder /opt/app-root/src/operators/endpointmetrics/manifests /usr/local/manifests

COPY --from=builder /opt/app-root/src/build/_output/bin/endpoint-monitoring-operator ${OPERATOR}

USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/endpoint-monitoring-operator"]

LABEL summary="endpoint-monitoring-operator" \
      io.k8s.display-name="endpoint-monitoring-operator" \
      maintainer="['maintainers@okd.io']" \
      description="endpoint-monitoring-operator"

