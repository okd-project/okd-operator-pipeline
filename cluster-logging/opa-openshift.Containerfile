FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ENV GOEXPERIMENT=strictfipsruntime
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOFLAGS=""

COPY --chown=default ./opa-openshift .

RUN go build -tags strictfipsruntime -a -ldflags '-s -w' -o ./opa-openshift .

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/opa-openshift /usr/bin/opa-openshift

EXPOSE 80
ENTRYPOINT ["/usr/bin/opa-openshift"]

LABEL io.k8s.display-name="OPA OpenShift" \
      io.k8s.description="An OPA-compatible API for making OpenShift access review requests"