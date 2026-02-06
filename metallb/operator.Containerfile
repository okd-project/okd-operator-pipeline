# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

# Copy the Go Modules manifests
COPY --chown=default go.mod go.mod
COPY --chown=default go.sum go.sum

# Copy the go source
COPY --chown=default main.go main.go
COPY --chown=default api/ api/
COPY --chown=default controllers/ controllers/
COPY --chown=default pkg/ pkg/
COPY --chown=default vendor/ vendor/
COPY --chown=default bindata/deployment/ bindata/deployment/

# Build
RUN CGO_ENABLED=0 GO111MODULE=on go build -a -mod=vendor -o manager main.go

FROM quay.io/centos/centos:stream9

WORKDIR /

COPY --from=builder /opt/app-root/src/manager .
COPY --from=builder /opt/app-root/src/bindata/deployment /bindata/deployment

ENTRYPOINT ["/manager"]

