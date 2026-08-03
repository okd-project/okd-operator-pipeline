# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS builder

ARG VERSION=0.0.0

COPY --chown=default ./operator .

# Upstream injects the git hash via .git; the submodule gitfile points outside
# the build context, so pass the version explicitly instead
RUN make container-binary-build INJECT_VERSION=v${VERSION}

FROM quay.io/centos/centos:stream9

WORKDIR /
COPY --from=builder /opt/app-root/src/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]
