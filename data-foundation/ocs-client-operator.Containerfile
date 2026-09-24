FROM registry.access.redhat.com/ubi10/go-toolset:1.26 as builder

ENV GOFLAGS=''

USER root
RUN dnf install -y glibc-devel
USER default

COPY --chown=default ./ocs-client-operator .

RUN go version | tee -a ./go.version

RUN CGO_ENABLED=0 GOOS=linux go build -a -o bin/ocs-client-operator cmd/main.go
RUN CGO_ENABLED=0 GOOS=linux go build -a -o bin/status-reporter ./service/status-report/main.go


FROM registry.access.redhat.com/ubi10/ubi-minimal:latest

RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/ocs-client-operator

COPY --from=builder /opt/app-root/src/bin/ocs-client-operator "$OPBIN"
COPY --from=builder /opt/app-root/src/bin/status-reporter /status-reporter
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OKD Container Storage client Operator" \
    summary="Provides the latest client Operator package." \
    io.k8s.display-name="OCS client Operator based on UBI 9" \
    io.k8s.description="OKD Container Storage client Operator based on UBI 9 Image"

RUN chmod +x "$OPBIN"

ENTRYPOINT ["/ocs-client-operator"]
