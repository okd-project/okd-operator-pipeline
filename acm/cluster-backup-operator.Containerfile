FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=cluster-backup-operator
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./cluster-backup-operator .

RUN go build -tags strictfipsruntime -a -o manager main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /

COPY --from=builder /opt/app-root/src/manager .

USER 65532:65532

ENTRYPOINT ["/manager"]

LABEL io.k8s.display-name="cluster-backup-operator"
