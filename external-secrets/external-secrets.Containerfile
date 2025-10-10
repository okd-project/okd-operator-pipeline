FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default external-secrets .

ENV GO_BUILD_TAGS=strictfipsruntime,openssl
ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOFLAGS=""

RUN go build -o bin/external-secrets -ldflags '-w -s' -tags ${GO_BUILD_TAGS} main.go

FROM registry.access.redhat.com/ubi9/ubi:latest

COPY --from=builder /opt/app-root/src/bin/external-secrets /bin/external-secrets
COPY external-secrets/LICENSE /licenses/

USER 65534:65534

LABEL summary="external-secrets" \
      release="${RELEASE_VERSION}" \
      io.k8s.display-name="external-secrets-controller" \
      io.k8s.description="external-secrets-container"

ENTRYPOINT ["/bin/external-secrets"]
