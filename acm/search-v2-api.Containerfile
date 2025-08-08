ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-search-v2-api
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default search-v2-api .

RUN go build -tags strictfipsruntime -trimpath -o main main.go

FROM registry.access.redhat.com/ubi9-minimal:latest

RUN microdnf -y update &&\
    microdnf install ca-certificates vi --nodocs -y &&\
    microdnf clean all

COPY --from=builder /opt/app-root/src/main /bin/main

ENV USER_UID=1001

EXPOSE 4010
USER ${USER_UID}
ENTRYPOINT ["/bin/main"]

LABEL summary="acm-search-v2-api" \
      io.k8s.display-name="acm-search-v2-api" \
      io.k8s.description="acm-search-v2-api" \
      maintainer="maintainers@okd.io" \
      description="acm-search-v2-api"
