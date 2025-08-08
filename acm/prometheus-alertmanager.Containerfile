FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=prometheus-alertmanager
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

USER root
RUN dnf install -y glibc-static && \
    dnf clean all
USER default

COPY --chown=default prometheus-alertmanager .

### Build a custom binary of promu 0.17 ###
WORKDIR $HOME/promu

# KEY CHANGE - Hack three lines from the promu build.go to remove -static flag
# RUN sed -i -e '180,182d' $REMOTE_SOURCES_DIR/promu/app/cmd/build.go
RUN go build -tags strictfipsruntime -o ./promu github.com/prometheus/promu

### Build prometheus-alertmanager using the custom promu binary ###
WORKDIR $HOME

#RUN microdnf install -y prometheus-promu
## Testing go mod vendor
#RUN go mod vendor

ENV BUILD_PROMU=false
#RUN source make build
#RUN source make common-build
RUN ./promu/promu build --cgo --prefix ./


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/amtool       /bin/amtool
COPY --from=builder /opt/app-root/src/alertmanager /bin/alertmanager
COPY --from=builder /opt/app-root/src/examples/ha/alertmanager.yml      /etc/alertmanager/alertmanager.yml

RUN mkdir -p /alertmanager && \
    chown -R nobody:nobody etc/alertmanager /alertmanager

USER       nobody
EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", \
             "--storage.path=/alertmanager" ]


LABEL summary="prometheus-alertmanager" \
      io.k8s.display-name="prometheus-alertmanager" \
      maintainer="['maintainers@okd.io']" \
      description="prometheus-alertmanager"
