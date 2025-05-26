# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.22 AS builder

COPY --chown=default .git/modules/ingress-node-firewall/ .git/modules/ingress-node-firewall/

# Copy the Go Modules manifests
COPY --chown=default ingress-node-firewall/operator/go.mod ingress-node-firewall/operator/go.mod
COPY --chown=default ingress-node-firewall/operator/go.sum ingress-node-firewall/operator/go.sum

# Copy the go source
COPY --chown=default ingress-node-firewall/operator/main.go ingress-node-firewall/operator/main.go
COPY --chown=default ingress-node-firewall/operator/api/ ingress-node-firewall/operator/api/
COPY --chown=default ingress-node-firewall/operator/controllers/ ingress-node-firewall/operator/controllers/
COPY --chown=default ingress-node-firewall/operator/pkg/ ingress-node-firewall/operator/pkg/
COPY --chown=default ingress-node-firewall/operator/vendor/ ingress-node-firewall/operator/vendor/
COPY --chown=default ingress-node-firewall/operator/bindata/manifests/ ingress-node-firewall/operator/bindata/manifests/

WORKDIR /opt/app-root/src/ingress-node-firewall/operator

# Build
RUN CGO_ENABLED=0 GO111MODULE=on go build -a -mod=vendor -o manager main.go

FROM quay.io/centos/centos:stream9

WORKDIR /

COPY --from=builder /opt/app-root/src/ingress-node-firewall/operator/manager .
COPY --from=builder /opt/app-root/src/ingress-node-firewall/operator/bindata/manifests /bindata/manifests

ENTRYPOINT ["/manager"]