FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=clusterclaims-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default clusterclaims-controller .

#RUN make -f Makefile.prow compile
RUN go mod vendor
RUN go build -tags strictfipsruntime -o build/_output/manager-clusterclaims ./cmd/clusterclaims/main.go
RUN go build -tags strictfipsruntime -o build/_output/manager-clusterpools-delete ./cmd/clusterpools/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=1001

# Add the binary
COPY --from=builder /opt/app-root/src/build/_output/manager-clusterclaims .
COPY --from=builder /opt/app-root/src/build/_output/manager-clusterpools-delete .

USER ${USER_UID}

LABEL summary="clusterclaims-controller" \
      io.k8s.display-name="clusterclaims-controller" \
      maintainer="['maintainers@okd.io']" \
      description="clusterclaims-controller"
