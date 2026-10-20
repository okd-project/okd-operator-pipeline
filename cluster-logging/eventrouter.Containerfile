FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1

COPY --chown=default ./eventrouter .

RUN go build -tags strictfipsruntime -mod=mod -o eventrouter

FROM quay.io/centos/centos:stream9-minimal

USER 1000
COPY --from=builder /opt/app-root/src/eventrouter /bin/eventrouter
CMD ["/bin/eventrouter", "-v", "3", "-logtostderr"]
