FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-prometheus-config-reloader
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default prometheus-operator .

#RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -tags strictfipsruntime -o prometheus-config-reloader cmd/prometheus-config-reloader/main.go
RUN go build -tags strictfipsruntime -o prometheus-config-reloader cmd/prometheus-config-reloader/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/prometheus-config-reloader /bin/prometheus-config-reloader

USER nobody

ENTRYPOINT ["/bin/prometheus-config-reloader"]

LABEL summary="acm-prometheus-config-reloader" \
      io.k8s.display-name="acm-prometheus-config-reloader" \
      maintainer="['maintainers@okd.io']" \
      description="acm-prometheus-config-reloader"
