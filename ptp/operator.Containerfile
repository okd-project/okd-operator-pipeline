FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder
COPY --chown=default ./ptp/operator ./ptp/operator
COPY --chown=default ./.git/modules/ptp/operator .git/modules/ptp/operator
WORKDIR /opt/app-root/src/ptp/operator
ENV CGO_ENABLED=0
ENV GOFLAGS="-buildvcs=false"
RUN make

FROM quay.io/centos/centos:stream9
COPY --from=builder /opt/app-root/src/ptp/operator/build/_output/bin/ptp-operator /usr/local/bin/
COPY --from=builder /opt/app-root/src/ptp/operator/manifests /manifests
COPY ./ptp/operator/bindata /bindata

ENTRYPOINT ["/usr/local/bin/ptp-operator"]
