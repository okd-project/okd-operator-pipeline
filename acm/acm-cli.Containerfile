FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=acm-cli
ENV COMPONENT_VERSION=${VERSION}
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./acm/acm-cli ./acm/acm-cli
COPY --chown=default .git/ .git/

WORKDIR /opt/app-root/src/acm/acm-cli

RUN GOFLAGS="-p=4" GOTAGS=${BUILD_TAGS} make build
RUN CI_UPSTREAM_BRANCH=release-2.14 GOFLAGS="-p=4" GOTAGS=${BUILD_TAGS} make build-and-package

FROM registry.access.redhat.com/ubi9/ubi:latest

RUN dnf -y update && \
    dnf clean all

RUN  mkdir /acm-cli
COPY --from=builder /opt/app-root/src/build/_output/* /acm-cli/
RUN  mv /acm-cli/acm-cli-server /usr/local/bin/

# Run as non-root user
USER 1001

ENTRYPOINT [ "/usr/local/bin/acm-cli-server" ]

LABEL io.k8s.display-name="ACM CLI"