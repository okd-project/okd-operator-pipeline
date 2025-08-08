ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-search-indexer
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default search-indexer .

RUN go build -tags strictfipsruntime -trimpath -o main main.go

FROM registry.access.redhat.com/ubi9-minimal:latest

RUN microdnf -y update && microdnf clean all
RUN microdnf install ca-certificates vi --nodocs -y && microdnf clean all

COPY --from=builder /opt/app-root/src/main /bin/main

ENV USER_UID=1001

EXPOSE 3010
USER ${USER_UID}
ENTRYPOINT ["/bin/main"]

LABEL summary="acm-search-indexer" \
      io.k8s.display-name="acm-search-indexer" \
      io.k8s.description="acm-search-indexer" \
      maintainer="maintainers@okd.io" \
      description="acm-search-indexer"
