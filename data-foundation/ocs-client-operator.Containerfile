FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

ENV GOFLAGS=''
ENV GOMODCACHE=$GOCACHE/pkg/mod

USER root
RUN dnf install -y glibc-devel
USER default

COPY --chown=default ./ocs-client-operator .

RUN go version | tee -a ./go.version

RUN GOOS=linux go build -mod=vendor -a -o bin/manager cmd/main.go
RUN GOOS=linux go build -mod=vendor -a -o ${GOBIN:-bin}/status-reporter ./service/status-report/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/manager
ENV ENTRYPOINT=/entrypoint

COPY --from=builder /opt/app-root/src/bin/manager "$OPBIN"
COPY --from=builder /opt/app-root/src/bin/status-reporter /status-reporter
COPY --from=builder /opt/app-root/src/hack/entrypoint.sh "$ENTRYPOINT"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OKD Container Storage client Operator" \
    summary="Provides the latest client Operator package." \
    io.k8s.display-name="OCS client Operator based on UBI 9" \
    io.k8s.description="OKD Container Storage client Operator based on UBI 9 Image"

RUN chmod +x "$OPBIN" "$ENTRYPOINT"

ENTRYPOINT ["/entrypoint"]
