FROM registry.access.redhat.com/ubi9/go-toolset:1.25 as builder

ENV GOPATH=/go/

USER root

WORKDIR /project-clone

COPY ./operator/ .

RUN export ARCH="$(uname -m)" && \
    if [[ ${ARCH} == "x86_64" ]]; then export ARCH="amd64"; \
    elif [[ ${ARCH} == "aarch64" ]]; then export ARCH="arm64"; fi && \
    CGO_ENABLED=1 GOEXPERIMENT=strictfipsruntime GOOS=linux GOARCH=${ARCH} GO111MODULE=on go build \
    -a -o _output/bin/project-clone \
    -gcflags all=-trimpath=/ \
    -asmflags all=-trimpath=/ \
    -tags strictfipsruntime \
    project-clone/main.go

FROM registry.access.redhat.com/ubi9-minimal:9.7

RUN microdnf install -y time git git-lfs nc && \
    microdnf clean all && rm -rf /var/cache/yum

WORKDIR /
COPY --from=builder /project-clone/_output/bin/project-clone /usr/local/bin/project-clone
COPY --from=builder /project-clone/build/bin /usr/local/bin

ENV USER_UID=1001 \
    USER_NAME=project-clone \
    HOME=/home/user

RUN /usr/local/bin/user_setup

USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD /usr/local/bin/project-clone
