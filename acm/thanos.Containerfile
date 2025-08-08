FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=thanos
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default thanos .

### Build a custom binary of promu 0.15 ###
WORKDIR $HOME/promu/

# KEY CHANGE - Hack three lines from the promu build.go to remove -static flag
RUN sed -i -e '184,186d' ./cmd/build.go
RUN go build -tags strictfipsruntime -o ./promu github.com/prometheus/promu

### Build thanos using the custom promu binary ###
WORKDIR $HOME

#RUN dnf install -y prometheus-promu
ENV BUILD_PROMU=false
RUN ./promu/promu build --cgo


FROM registry.access.redhat.com/ubi9/ubi:latest

RUN dnf -y update && dnf clean all

COPY --from=builder /opt/app-root/src/thanos /bin/thanos

ENTRYPOINT ["/bin/thanos"]

LABEL summary="thanos" \
      io.k8s.display-name="thanos" \
      maintainer="['maintainers@okd.io']" \
      description="thanos"

