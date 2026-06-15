# OKD build of the sandboxed containers kata-monitor image (osc-monitor-rhel9
# upstream). Adapted from the upstream Dockerfile: public UBI base images with
# floating tags instead of internal build-pinned ones, and the Red Hat LABEL
# block dropped. Build context is the kata-containers source tree vendored by
# the operator submodule:
#   ./operator/config/peerpods/podvm/cloud-api-adaptor/podvm-payload/kata-containers
FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

USER root
COPY ./VERSION /workdir/VERSION
COPY ./src/runtime /workdir/src/runtime
WORKDIR /workdir/src/runtime
# SKIP_GO_VERSION_CHECK avoids the version check pulling in yq at build time.
RUN SKIP_GO_VERSION_CHECK=true CGO_ENABLED=1 GOFLAGS=-tags=strictfipsruntime make monitor

# Add only required capabilities for the monitor
RUN chmod u-s kata-monitor
RUN setcap "cap_dac_override+eip" kata-monitor

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /workdir/src/runtime/kata-monitor /usr/bin/kata-monitor

CMD ["-h"]
ENTRYPOINT ["/usr/bin/kata-monitor"]
