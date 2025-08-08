FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-hypershift-addon-operator
ENV COMPONENT_VERSION=${CI_VERSION}
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4 -mod=mod"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default hypershift-addon-operator .

#RUN GOFLAGS="-p=4" make build --warn-undefined-variables
RUN go build -tags strictfipsruntime -o bin/hypershift-addon cmd/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# hypershift-addon-operator
COPY --from=builder /opt/app-root/src/bin/hypershift-addon .

LABEL summary="multicluster-engine-hypershift-addon-operator" \
      io.k8s.display-name="multicluster-engine-hypershift-addon-operator" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-hypershift-addon-operator"

