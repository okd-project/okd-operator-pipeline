FROM registry.access.redhat.com/ubi9/go-toolset:1.23 as builder

ENV GOFLAGS=''

COPY --chown=default ./ramen .

RUN go version | tee -a ./go.version

RUN GOOS=linux go build -a -o manager cmd/main.go

# Build stage 2
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/manager

COPY --from=builder /opt/app-root/src/manager "$OPBIN"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OKD Disaster Recovery Operator" \
    summary="Provides the latest Operator package for OKD Disastor Recovery." \
    io.k8s.display-name="ODR Operator based on UBI 9" \
    io.k8s.description="OKD Disaster Recovery Operator container based on UBI 9 Image"

RUN chmod +x "$OPBIN"

ENTRYPOINT ["/manager"]
