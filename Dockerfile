FROM registry.access.redhat.com/ubi9/ubi-init:latest

LABEL maintainer="luzuccar@redhat.com"

# gcc for cgo
RUN dnf install -y git gcc make diffutils && rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.20.5
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 d7ec48cde0d3d2be2c69203bc3e0a44de8660b9c09a6e85c4732a3f7dc442612

ENV OPERATOR_SDK_VERSION v1.29.0
ENV OPERATOR_SDK_BIN /usr/bin/operator-sdk
ENV KUSTOMIZE_VERSION v5.0.3
ENV OPM_VERSION v1.28.0
ENV OPM_BIN /usr/bin/opm
ENV OS linux
ENV ARCH amd64
ENV GOLANGCI_LINT_VERSION v1.53.2

RUN curl -fsSLo ${OPERATOR_SDK_BIN} "https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_VERSION}/operator-sdk_${OS}_${ARCH}" \
    && chmod 0755 $OPERATOR_SDK_BIN

RUN curl -fsSLo kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${OS}_${ARCH}.tar.gz"  \
    && tar -C /usr/bin -xzf kustomize.tar.gz \
    && rm kustomize.tar.gz

RUN curl -fsSLo ${OPM_BIN} "https://github.com/operator-framework/operator-registry/releases/download/${OPM_VERSION}/${OS}-${ARCH}-opm" \
    && chmod 0755 ${OPM_BIN}

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz

RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s ${GOLANGCI_LINT_VERSION}

ENV PATH $PATH:/bin:/usr/local/go/bin:/usr/bin/
ENV GOPATH /go
ENV GOCACHE /go/.cache/go-build
env GOLANGCI_LINT_CACHE /go/.cache/golangci-lint
ENV GOENV /go/.config/go/env

RUN mkdir -p /go/src /go/bin /go/pkg /go/build /go/.cache /go/.local \
    && chmod -R 0777 /go

RUN chown -R 1001:1001 /go

COPY uid_entrypoint.sh /go/

WORKDIR /go

USER 1001

ENTRYPOINT [ "./uid_entrypoint.sh" ]

