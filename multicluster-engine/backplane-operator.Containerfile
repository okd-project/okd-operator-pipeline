FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV COMPONENT_VERSION=$CI_VERSION
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default backplane-operator .

RUN GOOS=linux GOFLAGS="-p=4" go build -tags strictfipsruntime -a -o backplane-operator main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /app
COPY --from=builder /opt/app-root/src/backplane-operator .
COPY --from=builder /opt/app-root/src/pkg/templates pkg/templates

USER 65532:65532

ENTRYPOINT ["./backplane-operator"]

LABEL summary="multicluster-engine-operator" \
      io.k8s.display-name="multicluster-engine-operator" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-operator"
