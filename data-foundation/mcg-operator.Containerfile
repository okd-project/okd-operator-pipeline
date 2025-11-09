FROM quay.io/projectquay/golang:1.24 as builder

ENV GOFLAGS=''

WORKDIR /opt/app-root/src

COPY ./noobaa-operator .

RUN go version | tee ./go.version
RUN CGO_ENABLED=0 GOOS=linux go build -a -v -x -o bin/noobaa-operator

# Build stage 2
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/noobaa-operator \
    USER_UID=1001 \
    USER_NAME=noobaa-operator

RUN microdnf update -y && \
    microdnf install -y tar rsync && \
    microdnf clean all

RUN echo git rev-parse HEAD > /commit_hash

COPY --from=builder /opt/app-root/src/build/bin /usr/local/bin
COPY --from=builder /opt/app-root/src/bin/noobaa-operator ${OPERATOR}
COPY --from=builder /opt/app-root/src/go.version /go.version

#verifying that we have the binary
RUN ${OPERATOR} version

RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/noobaa-operator"]
CMD ["operator", "run"]

USER ${USER_UID}

LABEL io.k8s.display-name="MultiCloud Object Gateway Operator based on UBI 9" \
    io.k8s.description="MultiCloud Object Gateway Operator Container based on UBI 9 Image" \
    summary="Provides the latest MultiCloud Object Gateway Operator container for OKD Data Foundation" \
    description="OKD Data Foundation MultiCloud Object Gateway Operator container"