FROM registry.access.redhat.com/ubi8/go-toolset:1.23 AS builder-ubi8

COPY --chown=default ./cni .

RUN make clean && \
    GO_TAGS="" GO_BUILD_OPTS=CGO_ENABLED=1 make build


FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder-ubi9

COPY --chown=default ./cni .

RUN make clean && \
    GO_TAGS="" GO_BUILD_OPTS=CGO_ENABLED=1 make build

FROM quay.io/centos/centos:stream9-minimal

COPY --from=builder-ubi9 /opt/app-root/src/build/sriov /usr/bin/

RUN mkdir /usr/bin/rhel9
COPY --from=builder-ubi9 /opt/app-root/src/build/sriov /usr/bin/rhel9
RUN mkdir /usr/bin/rhel8
COPY --from=builder-ubi8 /opt/app-root/src/build/sriov /usr/bin/rhel8

WORKDIR /

COPY ./cni/images/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

LABEL io.k8s.display-name="SR-IOV CNI"