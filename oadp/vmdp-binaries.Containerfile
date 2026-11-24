FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

ARG CI_VERSION=dev
ARG GIT_COMMIT=unknown

COPY --chown=default ./oadp-vmdp .

RUN go mod download && go mod verify

# go-toolset is not root, so the binaries are built under the work directory, not /archives.
# The checksums are written from inside it, so they name the file as a user downloads it.
# "|| exit 1" because set -e does not stop on a failure inside an && list.
RUN mkdir -p archives && \
    for platform in linux/amd64 linux/arm64 windows/amd64 windows/arm64; do \
        os=$(echo $platform | cut -d'/' -f1); \
        arch=$(echo $platform | cut -d'/' -f2); \
        if [ "$os" = "windows" ]; then \
            out_name="oadp-vmdp_${os}_${arch}.exe"; \
        else \
            out_name="oadp-vmdp_${os}_${arch}"; \
        fi; \
        echo "Building oadp-vmdp for ${os}/${arch}..."; \
        CGO_ENABLED=0 GOOS=$os GOARCH=$arch \
            go build -trimpath -mod=mod \
            -ldflags="-s -w \
                -X github.com/kopia/kopia/repo.BuildVersion=${CI_VERSION} \
                -X github.com/kopia/kopia/repo.BuildInfo=${GIT_COMMIT} \
                -X github.com/kopia/kopia/repo.BuildGitHubRepo=github.com/openshift/oadp-vmdp" \
            -o archives/$out_name \
            . || exit 1; \
        (cd archives && sha256sum $out_name > $out_name.sha256) || exit 1; \
    done && \
    cp LICENSE archives/LICENSE

RUN CGO_ENABLED=0 GOOS=linux go build -o download-server ./cmd/downloads/


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/archives /archives
COPY --from=builder /opt/app-root/src/download-server /usr/local/bin/download-server

# The operator's Deployment sets runAsNonRoot and no runAsUser.
USER 65532:65532

EXPOSE 8080

CMD ["/usr/local/bin/download-server"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP VM Data Protection Downloads" \
        io.k8s.description="OKD API for Data Protection - download server for the oadp-vmdp binaries" \
        summary="OKD API for Data Protection - VM Data Protection Downloads" \
        maintainer="OKD Community <maintainers@okd.io>"
