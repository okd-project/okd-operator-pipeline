FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

COPY --chown=default ./operator .

RUN go version | tee -a ./go.version

RUN go mod verify

ENV CGO_ENABLED=1
ENV GOEXPERIMENT=strictfipsruntime
ENV GOOS=linux

RUN go build -tags strictfipsruntime -mod=vendor -ldflags "-s -w" -a -o lvms cmd/main.go

FROM quay.io/centos/centos:stream9-minimal

RUN microdnf update -y && \
    microdnf install -y util-linux xfsprogs e2fsprogs && \
    microdnf clean all

ENV OPBIN=/lvms

COPY --from=builder /opt/app-root/src/lvms "$OPBIN"
COPY --from=builder /opt/app-root/src/go.version /go.version

RUN chmod +x "$OPBIN"

USER 65532:65532

ENTRYPOINT ["/lvms"]