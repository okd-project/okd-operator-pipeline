ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=memcached_exporter
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

### Build a custom binary of promu 0.15 ###
COPY --chown=default memcached_exporter .
WORKDIR $HOME/promu/

# KEY CHANGE - Hack three lines from the promu build.go to remove -static flag
RUN sed -i -e '184,186d' $HOME/promu/cmd/build.go
RUN go build -tags strictfipsruntime -o ./promu github.com/prometheus/promu

### Build memcached_exporter using the custom promu binary ###
WORKDIR $HOME

ENV BUILD_PROMU=false
RUN ./promu/promu build --cgo

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/memcached_exporter /bin/memcached_exporter

USER       nobody
ENTRYPOINT ["/bin/memcached_exporter"]
EXPOSE     9150

LABEL summary="memcached-exporter" \
      io.k8s.display-name="memcached-exporter" \
      io.k8s.description="memcached-exporter" \
      maintainer="maintainers@okd.io" \
      description="memcached-exporter"
