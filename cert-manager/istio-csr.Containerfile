FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY istio-csr .
COPY istio-csr/LICENSE /licenses/

ENV GO_BUILD_TAGS=strictfipsruntime,openssl
ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOFLAGS=""

RUN cd $HOME/cmd && go build -o $HOME/_output/cert-manager-istio-csr -ldflags '-w -s' -tags ${GO_BUILD_TAGS} main.go

FROM quay.io/centos/centos:stream9

ARG SOURCE_DIR="/opt/app-root/src"

COPY --from=builder $SOURCE_DIR/_output/cert-manager-istio-csr /usr/local/bin/cert-manager-istio-csr
COPY --from=builder /licenses /licenses

USER 65534:65534

LABEL io.k8s.display-name="Cert Manager Istio CSR" \
      io.k8s.description="istio-csr is an agent that allows for Istio workload and control plane components \
      to be secured using cert-manager. "

ENTRYPOINT ["/usr/local/bin/cert-manager-istio-csr"]