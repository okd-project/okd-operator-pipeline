FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

COPY --chown=default ./eventrouter/go.mod ./eventrouter/go.sum ./
RUN go mod download
COPY --chown=default ./eventrouter/Makefile ./eventrouter/*.go ./
COPY --chown=default ./eventrouter/sinks ./sinks

RUN make build

FROM quay.io/centos/centos:stream9-minimal

USER 1000
COPY --from=builder /opt/app-root/src/eventrouter /bin/eventrouter
CMD ["/bin/eventrouter", "-v", "3", "-logtostderr"]