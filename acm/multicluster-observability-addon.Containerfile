ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-multicluster-observability-addon
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicluster-observability-addon .

RUN GOFLAGS="-p=4" go build -tags strictfipsruntime -a -o multicluster-observability-addon main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/multicluster-observability-addon /usr/local/bin/multicluster-observability-addon

ENTRYPOINT ["/usr/local/bin/multicluster-observability-addon"]

USER ${USER_UID}

LABEL summary="acm-multicluster-observability-addon" \
      io.k8s.display-name="acm-multicluster-observability-addon" \
      io.k8s.description="acm-multicluster-observability-addon" \
      maintainer="maintainers@okd.io" \
      description="acm-multicluster-observability-addon"
