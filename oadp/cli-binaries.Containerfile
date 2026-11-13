FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

ARG CI_VERSION=dev
ARG GIT_COMMIT=unknown

COPY --chown=default ./oadp-cli .

RUN go mod download && go mod verify

# go-toolset is not root, so the binaries are built under the work directory, not /archives.
# "|| exit 1" because set -e does not stop on a failure inside an && list.
RUN set -e && \
    mkdir -p archives && \
    for platform in linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64 windows/arm64; do \
        os=$(echo $platform | cut -d'/' -f1) && \
        arch=$(echo $platform | cut -d'/' -f2) && \
        if [ "$os" = "windows" ]; then \
            output="kubectl-oadp_${os}_${arch}.exe"; \
        else \
            output="kubectl-oadp_${os}_${arch}"; \
        fi && \
        echo "Building $output..." && \
        CGO_ENABLED=0 GOOS=$os GOARCH=$arch \
            go build -trimpath \
            -ldflags="-s -w \
                -X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=${CI_VERSION} \
                -X github.com/vmware-tanzu/velero/pkg/buildinfo.GitSHA=${GIT_COMMIT} \
                -X github.com/vmware-tanzu/velero/pkg/buildinfo.GitTreeState=clean" \
            -o archives/$output \
            . && \
        (cd archives && sha256sum $output > $output.sha256) || exit 1; \
    done && \
    chmod -x archives/kubectl-oadp_* && \
    cp LICENSE archives/LICENSE

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -o download-server ./cmd/downloads/


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/archives /archives
COPY --from=builder /opt/app-root/src/download-server /usr/local/bin/download-server

# The operator's Deployment sets runAsNonRoot and no runAsUser.
USER 65532:65532

EXPOSE 8080

CMD ["/usr/local/bin/download-server"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP CLI Downloads" \
        io.k8s.description="OKD API for Data Protection - download server for the kubectl-oadp binaries" \
        summary="OKD API for Data Protection - CLI Downloads" \
        maintainer="OKD Community <maintainers@okd.io>"
