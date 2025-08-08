FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=search-collector
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default search-collector .

# Hack for expected dir structure in make build
RUN GOGC=25 go build -tags strictfipsruntime -trimpath -o main main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update &&\
    microdnf install ca-certificates vi --nodocs -y &&\
    mkdir /licenses &&\
    microdnf clean all

ENV USER_UID=1001 \
    GOGC=50

COPY --from=builder /opt/app-root/src/main /bin/main

USER ${USER_UID}
ENTRYPOINT ["/bin/main"]

LABEL summary="search-collector" \
      io.k8s.display-name="search-collector" \
      maintainer="['maintainers@okd.io']" \
      description="search-collector"
