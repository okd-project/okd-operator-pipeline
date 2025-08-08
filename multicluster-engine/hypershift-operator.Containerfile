FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-hypershift-operator
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default hypershift .


#RUN GOFLAGS='-mod=vendor -p=4' GOTAGS=${BUILD_TAGS} make build
RUN GOFLAGS='-p=4' GOTAGS=${BUILD_TAGS} make build

# Re-build the hypershift and hcp CLI binaries with CGO_ENABLED=0
# because these are used outside of the hypershift operator container
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor go build -tags strictfipsruntime -gcflags=all='-N -l' -o bin/hypershift-no-cgo .
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor go build -tags strictfipsruntime -gcflags=all='-N -l' -o bin/hcp-no-cgo ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on go build -tags strictfipsruntime -gcflags=all='-N -l' -o bin/hypershift-no-cgo .
RUN CGO_ENABLED=0 GO111MODULE=on go build -tags strictfipsruntime -gcflags=all='-N -l' -o bin/hcp-no-cgo ./product-cli

# The upstream hypershift builds the hypershift CLI binary with CGO_ENABLED=0.
# Re-build it with CGO_ENABLED=1 to support FIPS
RUN CGO_ENABLED=1 GO111MODULE=on go build -tags strictfipsruntime -gcflags=all='-N -l' -o bin/hypershift .


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN  microdnf update -y && microdnf clean all
# tar is required to pull the hypershift CLI for the must-gather
RUN  microdnf install -y tar && microdnf clean all

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

COPY --from=builder $REMOTE_SOURCE_DIR/bin/hypershift /usr/bin/
COPY --from=builder $REMOTE_SOURCE_DIR/bin/hcp /usr/bin/
COPY --from=builder $REMOTE_SOURCE_DIR/bin/hypershift-no-cgo /usr/bin/
COPY --from=builder $REMOTE_SOURCE_DIR/bin/hcp-no-cgo /usr/bin/
COPY --from=builder $REMOTE_SOURCE_DIR/bin/hypershift-operator /usr/bin/
COPY --from=builder $REMOTE_SOURCE_DIR/bin/control-plane-operator /usr/bin/

RUN cd /usr/bin && \
    ln -s control-plane-operator ignition-server && \
    ln -s control-plane-operator konnectivity-socks5-proxy && \
    ln -s control-plane-operator availability-prober && \
    ln -s control-plane-operator token-minter

ENTRYPOINT /usr/bin/hypershift

LABEL summary="multicluster-engine-hypershift-operator" \
      io.k8s.display-name="multicluster-engine-hypershift-operator" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-hypershift-operator"
