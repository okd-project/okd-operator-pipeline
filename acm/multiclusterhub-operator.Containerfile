ARG VERSION
FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multiclusterhub-operator
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default multiclusterhub-operator .

RUN go build -tags strictfipsruntime -o multiclusterhub-operator main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /
COPY --from=builder /opt/app-root/src/multiclusterhub-operator /usr/local/bin/multiclusterhub-operator
COPY --from=builder /opt/app-root/src/pkg/templates/ /usr/local/templates/

USER 65532:65532

ENTRYPOINT ["multiclusterhub-operator"]

LABEL summary="multiclusterhub-operator" \
      io.k8s.display-name="multiclusterhub-operator" \
      io.k8s.description="multiclusterhub-operator" \
      maintainer="maintainers@okd.io" \
      description="multiclusterhub-operator"
