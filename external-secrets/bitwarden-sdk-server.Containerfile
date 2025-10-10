FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default bitwarden-sdk-server .

ENV GO_BUILD_TAGS=strictfipsruntime,openssl
ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOFLAGS=""

RUN CGO_LDFLAGS="-lm" go build -o bin/bitwarden-sdk-server -ldflags '-w -s' -tags ${GO_BUILD_TAGS} main.go
RUN mkdir state

FROM registry.access.redhat.com/ubi9/ubi:latest

COPY --from=builder /opt/app-root/src/bin/bitwarden-sdk-server /bin/bitwarden-sdk-server
COPY --from=builder --chown=65534:65534 /opt/app-root/src/state /state
COPY bitwarden-sdk-server/LICENSE /licenses/

EXPOSE 9998

USER 65534:65534

ENV CGO_ENABLED=1
ENV BW_SECRETS_MANAGER_STATE_PATH='/state'

LABEL summary="external-secrets" \
      release="${RELEASE_VERSION}" \
      io.k8s.display-name="external-secrets-controller" \
      io.k8s.description="external-secrets-container"

ENTRYPOINT [ "/bitwarden-sdk-server", "serve" ]