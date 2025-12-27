ARG BUILDVERSION
ARG BUILDVERSION_Y
ARG IMG_CLI

# Make kubectl & oc scripts available for copy
FROM $IMG_CLI as ose-cli

# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder
ARG BUILDVERSION
ARG IMAGE=quay.io/okderators/network-observability/cli:${BUILDVERSION}
ARG AGENT_IMAGE=quay.io/okderators/network-observability/ebpf-agent:${BUILDVERSION}

WORKDIR /opt/app-root

COPY cmd cmd
COPY main.go main.go
COPY go.mod go.mod
COPY go.sum go.sum
COPY vendor/ vendor/

# Build collector
ENV GOEXPERIMENT strictfipsruntime
RUN go build -tags strictfipsruntime -ldflags "-X 'main.buildVersion=${BUILDVERSION}' -X 'main.buildDate=`date +%Y-%m-%d\ %H:%M`'" -mod vendor -a -o build/network-observability-cli

# We still need Makefile & resources for oc-commands; copy them after go build for caching
COPY commands/ commands/
COPY res/ res/
COPY scripts/ scripts/
COPY Makefile Makefile
COPY .mk/ .mk/

# Embed commands in case users want to pull it from collector image
RUN USER=netobserv VERSION="$BUILDVERSION" IMAGE="$IMAGE" AGENT_IMAGE="$AGENT_IMAGE" make oc-commands

# Prepare output dir
RUN mkdir -p output

# Create final image from ubi + built binary and command
FROM registry.access.redhat.com/ubi9/ubi:latest
ARG BUILDVERSION
ARG BUILDVERSION_Y

WORKDIR /

COPY --from=builder /opt/app-root/build .
COPY --from=builder --chown=65532:65532 /opt/app-root/output /output
COPY LICENSE /licenses/
COPY README.downstream ./README

COPY --from=ose-cli /usr/bin/kubectl /usr/bin/kubectl
COPY --from=ose-cli /usr/bin/oc /usr/bin/oc

USER 65532:65532

ENTRYPOINT ["/network-observability-cli"]

LABEL distribution-scope="public"
LABEL url="https://github.com/okd-project/okderators-catalog-index"
LABEL vendor="OKD Community"
LABEL release=$BUILDVERSION
LABEL io.k8s.display-name="Network Observability CLI"
LABEL io.k8s.description="Network Observability CLI"
LABEL summary="Network Observability CLI"
LABEL maintainer="maintainers@okd.io"
LABEL io.openshift.tags="network-observability-cli"
LABEL description="Network Observability CLI is a lightweight Flow, Packet and Metrics visualization tool for on-demand monitoring."
LABEL version=$BUILDVERSION
