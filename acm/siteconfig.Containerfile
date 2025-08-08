ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-siteconfig
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default siteconfig .

RUN go build -tags strictfipsruntime -trimpath -o build/siteconfig-manager cmd/main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/build/siteconfig-manager /usr/local/bin/siteconfig-manager

ENV USER_UID=1001
USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/siteconfig-manager"]

LABEL summary="acm-siteconfig" \
      io.k8s.display-name="acm-siteconfig" \
      io.k8s.description="acm-siteconfig" \
      maintainer="maintainers@okd.io" \
      description="acm-siteconfig"
