ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=rbac-query-proxy
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GO111MODULE=on
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multicluster-observability-operator .

RUN go build -tags strictfipsruntime -a -installsuffix cgo -v -o main proxy/cmd/main.go

FROM registry.access.redhat.com/ubi9-minimal:latest

WORKDIR /
COPY --from=builder /opt/app-root/src/main rbac-query-proxy
EXPOSE 3002
ENTRYPOINT ["/rbac-query-proxy"]

LABEL summary="rbac-query-proxy" \
      io.k8s.display-name="rbac-query-proxy" \
      io.k8s.description="rbac-query-proxy" \
      maintainer="maintainers@okd.io" \
      description="rbac-query-proxy"
