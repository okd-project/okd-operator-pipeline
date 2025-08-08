FROM quay.io/centos/centos:stream9 AS builder

# Install oc binary
RUN cd /etc/yum.repos.d/ && \
    curl -O https://copr.fedorainfracloud.org/coprs/owenh/micro-okd/repo/centos-stream-9/owenh-micro-okd-centos-stream-9.repo && \
    dnf install -y openshift-clients

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS hypershift-builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-hypershift-operator
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default hypershift .

RUN CGO_ENABLED=1 GO111MODULE=on GOWORK=off GOFLAGS=-mod=vendor \
    go build -tags strictfipsruntime -gcflags=all='-N -l' -o bin/hypershift .


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf update -y && microdnf clean all
RUN microdnf install -y rsync tar gzip findutils \
  && microdnf clean all

# Copy oc binary
COPY --from=builder /usr/bin/oc /usr/bin/oc

# copy all collection scripts to /usr/bin
COPY backplane-must-gather/collection-scripts/* /usr/bin/

# copy hypershift binary to /usr/bin
COPY --from=hypershift-builder /opt/app-root/src/bin/hypershift /usr/bin/

ENTRYPOINT /usr/bin/gather

LABEL summary="multicluster-engine-must-gather" \
      io.k8s.display-name="multicluster-engine-must-gather" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-must-gather"
