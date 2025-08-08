ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=observatorium
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default observatorium .

RUN make observatorium

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/observatorium /bin/observatorium

LABEL summary="observatorium" \
      io.k8s.display-name="observatorium" \
      io.k8s.description="observatorium" \
      maintainer="maintainers@okd.io" \
      description="observatorium"

ENTRYPOINT ["/bin/observatorium"]
