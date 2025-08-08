FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=insights-client
ENV COMPONENT_VERSION=$VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default ./insights-client .

RUN mkdir output
RUN go build -tags strictfipsruntime -trimpath -o main main.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf install ca-certificates vi --nodocs -y &&\
    mkdir /licenses &&\
    microdnf clean all

ENV USER_UID=1001

COPY --from=builder /opt/app-root/src/main /bin/main


EXPOSE 3030
USER ${USER_UID}
ENTRYPOINT ["/bin/main"]


LABEL summary="insights-client" \
      io.k8s.display-name="insights-client" \
      maintainer="['maintainers@okd.io']" \
      description="insights-client"
