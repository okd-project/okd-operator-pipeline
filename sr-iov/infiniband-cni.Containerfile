FROM registry.access.redhat.com/ubi8/go-toolset:1.22 AS builder-ubi8

COPY --chown=default ./infiniband-cni/ .

RUN make clean && \
    GO_TAGS="" GO_BUILD_OPTS=CGO_ENABLED=1 make build


FROM registry.access.redhat.com/ubi9/go-toolset:1.22 AS builder-ubi9

COPY --chown=default ./infiniband-cni .

RUN make clean && \
   GO_TAGS="" GO_BUILD_OPTS=CGO_ENABLED=1 make build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder-ubi9 /opt/app-root/src/build/ib-sriov /usr/bin/

RUN mkdir /usr/bin/rhel9
COPY --from=builder-ubi9 /opt/app-root/src/build/ib-sriov /usr/bin/rhel9
RUN mkdir /usr/bin/rhel8
COPY --from=builder-ubi8 /opt/app-root/src/build/ib-sriov /usr/bin/rhel8

WORKDIR /


COPY ./infiniband-cni/images/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

LABEL io.k8s.display-name="InfiniBand SR-IOV CNI"