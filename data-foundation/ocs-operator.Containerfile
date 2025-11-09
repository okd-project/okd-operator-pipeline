FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

ARG CI_VERSION

ENV GOFLAGS=''

COPY --chown=default ./ocs-operator .

RUN go version | tee ./go.version
RUN echo "$VER"
RUN GOOS=linux go build -a -ldflags "-X github.com/red-hat-storage/ocs-operator/v4/version.Version=${CI_VERSION}" -o bin/ocs-operator ./main.go
RUN GOOS=linux go build -a -ldflags "-X github.com/red-hat-storage/ocs-operator/v4/version.Version=${CI_VERSION}" -o bin/provider-api ./services/provider/main.go
RUN GOOS=linux go build -a -o bin/onboarding-validation-keys-gen ./onboarding-validation-keys-generator/main.go
RUN GOOS=linux go build -a -o bin/ux-backend-server ./services/ux-backend/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Update the image to get the latest CVE updates
RUN microdnf update -y && \
    microdnf clean all

ENV OPBIN=/usr/local/bin/ocs-operator
ENV PRBIN=/usr/local/bin/provider-api
ENV PROMRULES=/ocs-prometheus-rules/
ENV UXBIN=/usr/local/bin/ux-backend-server
ENV SECGEN=/usr/local/bin/onboarding-validation-keys-gen
ENV ENTRYPOINT=/usr/local/bin/entrypoint

COPY --from=builder /opt/app-root/src/bin/ocs-operator "$OPBIN"
COPY --from=builder /opt/app-root/src/bin/provider-api "$PRBIN"
COPY --from=builder /opt/app-root/src/metrics/deploy/*rules*.yaml "$PROMRULES"
COPY --from=builder /opt/app-root/src/bin/ux-backend-server "$UXBIN"
COPY --from=builder /opt/app-root/src/bin/onboarding-validation-keys-gen "$SECGEN"
COPY --from=builder /opt/app-root/src/hack/entrypoint.sh "$ENTRYPOINT"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL description="OKD Container Storage Operator container" \
    summary="Provides the latest OCS Operator package for OKD Data Foundation." \
    io.k8s.display-name="OCS Operator based on UBI 9" \
    io.k8s.description="OCS Operator container based on UBI 9 Image"

RUN chmod +x "$OPBIN" "$PRBIN" "$UXBIN" "$SECGEN" "$ENTRYPOINT"

USER operator

ENTRYPOINT ["/usr/local/bin/entrypoint"]