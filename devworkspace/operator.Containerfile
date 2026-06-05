FROM registry.access.redhat.com/ubi9/go-toolset:1.25 as builder

ENV GOPATH=/go/

USER root

WORKDIR /devworkspace-operator

COPY ./operator/ .

RUN sed -i \
  -e 's/CGO_ENABLED=0/CGO_ENABLED=1 GOEXPERIMENT=strictfipsruntime/g' \
  -e '/-asmflags/a\\t  -tags strictfipsruntime \\' \
  Makefile

RUN make compile-devworkspace-controller
RUN make compile-webhook-server

FROM registry.access.redhat.com/ubi9-minimal:9.7

RUN microdnf clean all && rm -rf /var/cache/yum

WORKDIR /
COPY --from=builder /devworkspace-operator/_output/bin/devworkspace-controller /usr/local/bin/devworkspace-controller
COPY --from=builder /devworkspace-operator/_output/bin/webhook-server /usr/local/bin/webhook-server
COPY --from=builder /devworkspace-operator/build/bin /usr/local/bin

ENV USER_UID=1001 \
    USER_NAME=devworkspace-controller

RUN /usr/local/bin/user_setup

USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD /usr/local/bin/devworkspace-controller
