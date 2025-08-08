FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=provider-credential-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default provider-credential-controller .

#RUN make -f Makefile.prow compile
RUN go mod vendor
RUN go build -tags strictfipsruntime -o build/_output/manager ./cmd/manager/main.go
RUN go build -tags strictfipsruntime -o build/_output/old-provider-connection ./cmd/oldproviderconnection/main.go


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV USER_UID=1001

# Add the binaries
COPY --from=builder /opt/app-root/src/build/_output/manager .
COPY --from=builder /opt/app-root/src/build/_output/old-provider-connection .

USER ${USER_UID}

LABEL summary="provider-credential-controller" \
      io.k8s.display-name="provider-credential-controller" \
      maintainer="['maintainers@okd.io']" \
      description="provider-credential-controller"
