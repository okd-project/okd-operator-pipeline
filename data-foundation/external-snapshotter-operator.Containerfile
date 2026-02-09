FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

COPY --chown=default external-snapshotter .

RUN go version | tee -a ./go.version

RUN GOOS=linux go build -mod=vendor -a -o bin/snapshot-controller cmd/snapshot-controller/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPBIN=/snapshot-controller

ARG BUILD_SRC=/opt/app-root/src

COPY --from=builder $BUILD_SRC/bin/snapshot-controller "$OPBIN"
COPY --from=builder $BUILD_SRC/go.version /go.version

RUN chmod +x "$OPBIN"

ENTRYPOINT ["/snapshot-controller"]

LABEL description="OKD Data Foundation External Snapshotter Operator"
LABEL summary="Provides the latest External Snapshotter Operator package for OKD Data Foundation."
