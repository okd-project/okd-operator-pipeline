FROM registry.access.redhat.com/ubi9/go-toolset:1.22 AS builder-ubi9

COPY --chown=default ./rdma-cni .

RUN make clean && \
    GO_TAGS="" GO_BUILD_OPTS="CGO_ENABLED=1 GOOS=$(go env GOOS) GOARCH=$(go env GOARCH)" make build


FROM registry.access.redhat.com/ubi8/go-toolset:1.22 AS builder-ubi8

COPY --chown=default ./rdma-cni .

RUN make clean && \
    GO_TAGS="" GO_BUILD_OPTS="CGO_ENABLED=1 GOOS=$(go env GOOS) GOARCH=$(go env GOARCH)" make build

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

COPY --from=builder-ubi9 /opt/app-root/src/build/rdma /usr/bin/

RUN mkdir /usr/bin/ubi9
COPY --from=builder-ubi9 /opt/app-root/src/build/rdma /usr/bin/ubi9
RUN mkdir /usr/bin/ubi8
COPY --from=builder-ubi8 /opt/app-root/src/build/rdma /usr/bin/ubi8

WORKDIR /

COPY ./rdma-cni/images/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

LABEL io.k8s.display-name="RDMA CNI"