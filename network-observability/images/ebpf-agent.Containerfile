ARG BUILDVERSION
ARG BUILDVERSION_Y

# Build the manager binary
FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder
ARG BUILDVERSION

WORKDIR /opt/app-root

# Copy the go manifests and source
COPY bpf/ bpf/
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY vendor/ vendor/
COPY go.mod go.mod
COPY go.sum go.sum

# Build
ENV GOEXPERIMENT strictfipsruntime
RUN go build -tags strictfipsruntime -ldflags "-X 'main.buildVersion=${BUILDVERSION}' -X 'main.buildDate=`date +%Y-%m-%d\ %H:%M`'" -mod vendor -a -o bin/netobserv-ebpf-agent cmd/netobserv-ebpf-agent.go

# Create final image from minimal + built binary
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
ARG BUILDVERSION
ARG BUILDVERSION_Y

WORKDIR /
COPY --from=builder /opt/app-root/bin/netobserv-ebpf-agent .
COPY LICENSE /licenses/
COPY bpf/LICENSE /licenses/LICENSE-GPL
COPY README.downstream /licenses/README
USER 65532:65532

ENTRYPOINT ["/netobserv-ebpf-agent"]

LABEL distribution-scope="public"
LABEL url="https://github.com/okd-project/okderators-catalog-index"
LABEL vendor="OKD Community"
LABEL release=$BUILDVERSION
LABEL io.k8s.display-name="Network Observability eBPF Agent"
LABEL io.k8s.description="Network Observability eBPF Agent"
LABEL summary="Network Observability eBPF Agent"
LABEL maintainer="maintainers@okd.io"
LABEL io.openshift.tags="network-observability-ebpf-agent"
LABEL description="The Network Observability eBPF Agent allows collecting and aggregating all the ingress and egress flows on a Linux host."
LABEL version=$BUILDVERSION
