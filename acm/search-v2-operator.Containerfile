ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-search-v2-operator
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default search-v2-operator .

RUN go build -tags strictfipsruntime -a -o manager main.go

FROM registry.access.redhat.com/ubi9-minimal:9.6-1747218906

ENV USER_UID=1001 \
    USER_NAME=search-v2-operator

RUN microdnf update -y && microdnf clean all

# install operator binary
COPY --from=builder /opt/app-root/src/manager .
USER ${USER_UID}

ENTRYPOINT ["/manager"]

LABEL summary="acm-search-v2-operator" \
      io.k8s.display-name="acm-search-v2-operator" \
      io.k8s.description="acm-search-v2-operator" \
      maintainer="maintainers@okd.io" \
      description="acm-search-v2-operator"
