# Build stage 1---> Build cli
FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

# Override GOFLAGS
ENV GOFLAGS=''

# Copy remote sources
COPY --chown=default .git .git
COPY --chown=default data-foundation/noobaa-operator data-foundation/noobaa-operator
COPY --chown=default data-foundation/odf-cli data-foundation/odf-cli

# Build MCG CLI
WORKDIR $HOME/data-foundation/noobaa-operator

RUN git rev-parse HEAD > ./noobaa_commit_hash

RUN CGO_ENABLED=0 GO111MODULE=on go build -o noobaa-operator-native -ldflags="-s -w" && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GO111MODULE=on go build -o noobaa-operator-amd64 -ldflags="-s -w" && \
    GOOS=windows GOARCH=amd64 CGO_ENABLED=0 GO111MODULE=on go build -o noobaa-operator-windows -ldflags="-s -w" && \
    GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 GO111MODULE=on go build -o noobaa-operator-darwin -ldflags="-s -w" && \
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 GO111MODULE=on go build -o noobaa-operator-arm64 -ldflags="-s -w" && \
    GOOS=linux GOARCH=ppc64le CGO_ENABLED=0 GO111MODULE=on go build -o noobaa-operator-ppc64le -ldflags="-s -w" && \
    GOOS=linux GOARCH=s390x CGO_ENABLED=0 GO111MODULE=on go build -o noobaa-operator-s390x -ldflags="-s -w"


## Build ODF CLI
WORKDIR $HOME/data-foundation/odf-cli

RUN git rev-parse HEAD > ./odf_commit_hash

RUN CGO_ENABLED=0 GO111MODULE=on go build -o odf-cli-native -ldflags="-s -w" ./cmd/odf/main.go && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GO111MODULE=on go build -o odf-cli-amd64 -ldflags="-s -w" ./cmd/odf/main.go && \
    GOOS=windows GOARCH=amd64 CGO_ENABLED=0 GO111MODULE=on go build -o odf-cli-windows -ldflags="-s -w" ./cmd/odf/main.go && \
    GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 GO111MODULE=on go build -o odf-cli-darwin -ldflags="-s -w" ./cmd/odf/main.go && \
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 GO111MODULE=on go build -o odf-cli-arm64 -ldflags="-s -w" ./cmd/odf/main.go && \
    GOOS=linux GOARCH=ppc64le CGO_ENABLED=0 GO111MODULE=on go build -o odf-cli-ppc64le -ldflags="-s -w" ./cmd/odf/main.go && \
    GOOS=linux GOARCH=s390x CGO_ENABLED=0 GO111MODULE=on go build -o odf-cli-s390x -ldflags="-s -w" ./cmd/odf/main.go

# Build stage 2
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV MCG=/usr/share/mcg/
ENV ODF=/usr/share/odf/

RUN microdnf update -y && \
    microdnf install -y tar rsync && \
    microdnf clean all

COPY --from=builder /opt/app-root/src/data-foundation/noobaa-operator/noobaa_commit_hash /noobaa_commit_hash
COPY --from=builder /opt/app-root/src/data-foundation/odf-cli/odf_commit_hash /odf_commit_hash

COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/noobaa-operator/noobaa-operator-native /usr/bin/noobaa
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/noobaa-operator/noobaa-operator-amd64 ${MCG}/linux/noobaa-amd64
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/noobaa-operator/noobaa-operator-arm64 ${MCG}/linux/noobaa-arm64
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/noobaa-operator/noobaa-operator-ppc64le ${MCG}/linux/noobaa-ppc64le
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/noobaa-operator/noobaa-operator-s390x ${MCG}/linux/noobaa-s390x
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/noobaa-operator/noobaa-operator-windows ${MCG}/windows/noobaa.exe
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/noobaa-operator/noobaa-operator-darwin ${MCG}/macosx/noobaa
COPY --from=builder --chmod=644 /opt/app-root/src/data-foundation/noobaa-operator/doc/noobaa.1 /usr/share/man/man1/noobaa.1

COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/odf-cli/odf-cli-native /usr/bin/odf
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/odf-cli/odf-cli-amd64 ${ODF}/linux/odf-amd64
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/odf-cli/odf-cli-arm64 ${ODF}/linux/odf-arm64
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/odf-cli/odf-cli-ppc64le ${ODF}/linux/odf-ppc64le
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/odf-cli/odf-cli-s390x ${ODF}/linux/odf-s390x
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/odf-cli/odf-cli-windows ${ODF}/windows/odf.exe
COPY --from=builder --chmod=755 /opt/app-root/src/data-foundation/odf-cli/odf-cli-darwin ${ODF}/macosx/odf

LABEL io.k8s.display-name="ODF CLI contains MCG and ODF CLI based on UBI 9" \
    io.k8s.description="OKD Data Foundation CLI Container based on UBI 9 Image"

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/bin/bash"]

RUN rm -rf /var/log/*