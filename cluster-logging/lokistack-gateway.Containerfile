FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOFLAGS="-p=4"

COPY --chown=default ./observatorium-api .

RUN go build -tags strictfipsruntime -a -ldflags '-s -w' -o lokistack-gateway .

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/lokistack-gateway /usr/bin/lokistack-gateway

EXPOSE 80
ENTRYPOINT ["/usr/bin/lokistack-gateway"]

LABEL io.k8s.display-name="OpenShift Lokistack Gateway" \
      io.k8s.description="Horizontally-scalable authn/authz-securing reverse proxy for Loki."
