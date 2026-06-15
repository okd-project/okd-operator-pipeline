FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ARG CI_VERSION

ENV GOFLAGS=''

WORKDIR /opt/app-root/src

COPY --chown=default blackbox-exporter .

RUN go version | tee ./go.version
RUN CGO_ENABLED=0 GOOS=linux go build -a -o bin/blackbox-exporter main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV EXBIN=/usr/local/bin/blackbox-exporter

COPY --from=builder /opt/app-root/src/bin/blackbox-exporter "$EXBIN"
COPY --from=builder /opt/app-root/src/blackbox.yml /etc/blackbox_exporter/config.yml
COPY --from=builder /opt/app-root/src/go.version /go.version

RUN chmod +x "$EXBIN"

ENTRYPOINT ["/usr/local/bin/blackbox-exporter"]
CMD ["--config.file=/etc/blackbox_exporter/config.yml"]

LABEL description="OKD Data Foundation Blackbox Exporter" \
    summary="Provides the latest Blackbox Exporter package for OKD Data Foundation." \
    io.k8s.display-name="ODF Blackbox Exporter based on UBI 9" \
    io.k8s.description="ODF Blackbox Exporter container based on UBI 9"
