FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default ./non-admin .

ENV BUILDTAGS strictfipsruntime
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -tags "$BUILDTAGS" -mod=mod -a -o manager cmd/main.go


FROM registry.access.redhat.io/ubi9/ubi-minimal:latest

RUN microdnf -y update && microdnf clean all
COPY --from=builder /opt/app-root/src/manager /manager

USER 65532:65532

ENTRYPOINT ["/manager"]

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP Non-Admin" \
        io.k8s.description="OKD API for Data Protection - Non-Admin" \
        summary="OKD API for Data Protection - Non-Admin" \
        maintainer="OKD Community <maintainers@okd.io?"
