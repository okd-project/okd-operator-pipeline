FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=thanos-receive-controller
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=""
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default thanos-receive-controller .

#RUN make thanos-receive-controller
RUN go mod vendor && GO111MODULE=on go build -tags strictfipsruntime -mod vendor -v


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/thanos-receive-controller /bin/thanos-receive-controller

ENTRYPOINT ["/bin/thanos-receive-controller"]

LABEL summary="thanos-receive-controller" \
      io.k8s.display-name="thanos-receive-controller" \
      maintainer="['maintainers@okd.io']" \
      description="thanos-receive-controller"
