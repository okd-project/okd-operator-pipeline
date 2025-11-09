FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

ENV GOFLAGS=''

COPY --chown=default ./odf-operator .

RUN go version | tee -a ./go.version

RUN GOOS=linux go build -mod=vendor -a -o bin/odf-operator ./main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/manager

COPY --from=builder /opt/app-root/src/bin/odf-operator "$OPBIN"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OpenShift Data Foundation Operator" \
    summary="Provides the latest Operator package for OpenShift Data Foundation." \
    io.k8s.display-name="ODF Operator based on RHEL 9" \
    io.k8s.description="OpenShift Data Foundation Operator container based on Red Hat Enterprise Linux 9 Image"

RUN chmod +x "$OPBIN"

ENTRYPOINT ["/manager"]