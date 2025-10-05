FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default cert-manager .
COPY --chown=default cert-manager/LICENSE /licenses/

ENV GO_BUILD_TAGS=strictfipsruntime,openssl
ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOFLAGS=""

RUN cd $HOME/cmd/acmesolver && go build -o $HOME/_output/acmesolver -ldflags '-w -s' -tags ${GO_BUILD_TAGS} main.go
RUN cd $HOME/cmd/cainjector && go build -o $HOME/_output/cainjector -ldflags '-w -s' -tags ${GO_BUILD_TAGS} main.go
RUN cd $HOME/cmd/controller && go build -o $HOME/_output/controller -ldflags '-w -s' -tags ${GO_BUILD_TAGS} main.go
RUN cd $HOME/cmd/webhook && go build -o $HOME/_output/webhook -ldflags '-w -s' -tags ${GO_BUILD_TAGS} main.go

FROM quay.io/centos/centos:stream9

ENV SOURCE_DIR=/opt/app-root/src

COPY --from=builder $SOURCE_DIR/_output/acmesolver /app/cmd/acmesolver/acmesolver
COPY --from=builder $SOURCE_DIR/_output/cainjector /app/cmd/cainjector/cainjector
COPY --from=builder $SOURCE_DIR/_output/controller /app/cmd/controller/controller
COPY --from=builder $SOURCE_DIR/_output/webhook /app/cmd/webhook/webhook
COPY --from=builder /licenses /licenses

USER 65534:65534

LABEL io.k8s.display-name="Cert Manager" \
      io.k8s.description="Automatically provision and manage TLS certificates in Kubernetes"