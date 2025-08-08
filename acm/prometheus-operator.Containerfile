FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-prometheus-operator
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default prometheus-operator .

#RUN GOOS=linux GOARCH=amd64 go build -tags strictfipsruntime -o operator cmd/operator/main.go
RUN go build -tags strictfipsruntime -o operator cmd/operator/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/operator /bin/operator

USER nobody

ENTRYPOINT ["/bin/operator"]

LABEL summary="acm-prometheus-operator" \
      io.k8s.display-name="acm-prometheus-operator" \
      maintainer="['maintainers@okd.io']" \
      description="acm-prometheus-operator"
