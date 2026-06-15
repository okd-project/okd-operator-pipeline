# OKD build of the sandboxed containers must-gather image (osc-must-gather-rhel9
# upstream). Adapted from the upstream Dockerfile: the builder stage providing
# oc and the base gather script is the OKD payload's must-gather image (passed
# as MUST_GATHER_IMAGE by build.sh via get_payload_component) instead of
# registry.redhat.io/openshift4/ose-must-gather-rhel9, the runtime base is a
# floating public UBI tag, and the Red Hat LABEL block is dropped.
# Build context is ./operator/must-gather.
ARG MUST_GATHER_IMAGE
FROM ${MUST_GATHER_IMAGE} AS builder

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# For gathering data from nodes
RUN microdnf update -y && \
    microdnf install tar rsync iproute util-linux pciutils nftables -y && \
    microdnf clean all

COPY --from=builder /usr/bin/oc /usr/bin/oc

# Save original gather script
COPY --from=builder /usr/bin/gather /usr/bin/gather_original

# Copy all collection scripts to /usr/bin
COPY collection-scripts/* /usr/bin/

# Copy node-gather resources to /etc
COPY node-gather/node-gather-crd.yaml /etc/
COPY node-gather/node-gather-ds.yaml /etc/

ENTRYPOINT /usr/bin/gather
