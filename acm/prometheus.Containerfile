FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=prometheus
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default prometheus .

### Build a custom binary of promu 0.17 ###
WORKDIR $HOME/promu

# KEY CHANGE - Hack three lines from the promu build.go to remove -static flag
# RUN sed -i -e '180,182d' $REMOTE_SOURCES_DIR/promu/app/cmd/build.go
RUN go build -tags strictfipsruntime -o ./promu github.com/prometheus/promu

### Build prometheus using the custom promu binary ###
WORKDIR $HOME

#RUN microdnf install -y prometheus-promu

ENV BUILD_PROMU=false

#RUN make common-build
RUN ./promu/promu build --cgo --prefix ./


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# COPY --from=builder /opt/app-root/src/<content>

COPY --from=builder /opt/app-root/src/prometheus        /bin/prometheus
COPY --from=builder /opt/app-root/src/promtool          /bin/promtool

COPY --from=builder /opt/app-root/src/documentation/examples/prometheus.yml  /etc/prometheus/prometheus.yml
COPY --from=builder /opt/app-root/src/console_libraries/                     /usr/share/prometheus/console_libraries/
COPY --from=builder /opt/app-root/src/consoles/                              /usr/share/prometheus/consoles/
COPY --from=builder /opt/app-root/src/LICENSE                                /LICENSE
COPY --from=builder /opt/app-root/src/NOTICE                                 /NOTICE


WORKDIR    /prometheus
RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
    chown -R nobody:nobody /etc/prometheus /prometheus

USER       nobody
EXPOSE     9090
VOLUME     [ "/prometheus" ]
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus", \
             "--web.console.libraries=/usr/share/prometheus/console_libraries", \
             "--web.console.templates=/usr/share/prometheus/consoles" ]

LABEL summary="prometheus" \
      io.k8s.display-name="prometheus" \
      maintainer="['maintainers@okd.io']" \
      description="prometheus"
