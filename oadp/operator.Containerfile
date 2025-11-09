FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder


COPY --chown=default ./operator .

RUN go mod download

# Copy the go source
COPY --chown=default ./operator/cmd/main.go ./cmd/main.go
COPY --chown=default ./operator/api/ ./api/
COPY --chown=default ./operator/internal/controller/ ./internal/controller/
COPY --chown=default ./operator/pkg/ ./pkg/

# Build
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -mod=mod -a -tags strictfipsruntime -o ./bin/manager cmd/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && microdnf -y install openssl && microdnf -y reinstall tzdata && microdnf clean all

WORKDIR /

COPY --from=builder /opt/app-root/src/bin/manager .
USER 65532:65532
ENTRYPOINT ["/manager"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP Operator" \
        io.k8s.description="OKD API for Data Protection - Operator" \
        summary="OKD API for Data Protection - Operator" \
        maintainer="OKD Community <maintainers@okd.io>"
