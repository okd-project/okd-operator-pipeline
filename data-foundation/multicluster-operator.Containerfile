FROM quay.io/projectquay/golang:1.23 as builder

ENV GOFLAGS=''

WORKDIR /opt/app-root/src

COPY ./odf-multicluster-orchestrator .

RUN go version | tee -a ./go.version

RUN GOOS=linux go build -a -o bin/odf-multicluster-operator ./main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/manager

COPY --from=builder /opt/app-root/src/bin/odf-multicluster-operator "$OPBIN"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OKD Data Foundation Multicluster Orchestrator" \
    summary="Provides the latest Operator package for OKD Data Foundation Multicluster Orchestrator." \
    io.k8s.display-name="ODF Multicluster Orchestrator based on UBI 9" \
    io.k8s.description="OKD Data Foundation Multicluster Orchestrator based on UBI 9 Image"

RUN chmod +x "$OPBIN"

ENTRYPOINT ["/manager"]