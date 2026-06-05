FROM registry.access.redhat.com/ubi9/go-toolset:1.25 as builder

ARG DS_VERSION
ENV GOPATH=/go/
ENV CGO_ENABLED=1

USER root

WORKDIR /che-operator

COPY ./che-operator/api/ api/
COPY ./che-operator/controllers/ controllers/
COPY ./che-operator/pkg/ pkg/
COPY ./che-operator/vendor/ vendor/
COPY ./che-operator/go.mod go.mod
COPY ./che-operator/go.sum go.sum
COPY ./che-operator/cmd/main.go cmd/main.go

# editors-definitions live in the upstream che-operator repo root (not in build/)
COPY ./che-operator/editors-definitions /tmp/editors-definitions
RUN go version
RUN cd /tmp/editors-definitions && find . -maxdepth 1 -type f ! -name '*.yaml' -delete && ls -l

RUN mkdir -p /tmp/header-rewrite-traefik-plugin
COPY ./header-rewrite-traefik-plugin/headerRewrite.go /tmp/header-rewrite-traefik-plugin/headerRewrite.go
COPY ./header-rewrite-traefik-plugin/.traefik.yml /tmp/header-rewrite-traefik-plugin/.traefik.yml

COPY ./che-operator/config/manager/manager.yaml config/manager/manager.yaml

# Run tests (no branding needed for OKD — keep upstream eclipse-che branding)
RUN MOCK_API=true go test -mod=vendor -v ./... && rm config/manager/manager.yaml

RUN export ARCH="$(uname -m)" && \
    if [[ "${ARCH}" == "x86_64" ]]; then export ARCH="amd64"; \
    elif [[ "${ARCH}" == "aarch64" ]]; then export ARCH="arm64"; fi && \
    GOOS=linux GOARCH=${ARCH} GO111MODULE=on go build -mod=vendor -a -o che-operator cmd/main.go

FROM registry.access.redhat.com/ubi9-minimal:9.7

COPY ./che-operator/LICENSE /licenses/LICENSE
COPY --from=builder /tmp/editors-definitions /tmp/editors-definitions
COPY --from=builder /tmp/header-rewrite-traefik-plugin /tmp/header-rewrite-traefik-plugin
COPY --from=builder /che-operator/che-operator /manager

USER 1001
ENTRYPOINT ["/manager"]
