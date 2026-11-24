FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

COPY --chown=default ./vm-file-restore .

RUN CGO_ENABLED=0 GOOS=linux go build -a -o manager cmd/main.go


FROM gcr.io/distroless/static:nonroot

WORKDIR /
COPY --from=builder /opt/app-root/src/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP VM File Restore" \
        io.k8s.description="OKD API for Data Protection - VM File Restore Controller" \
        summary="OKD API for Data Protection - VM File Restore Controller" \
        maintainer="OKD Community <maintainers@okd.io>"
