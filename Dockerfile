FROM registry.access.redhat.com/ubi9/ubi-init:latest

LABEL maintainer="luzuccar@redhat.com"

# gcc for cgo
RUN dnf update -y && dnf install -y git gcc make diffutils nodejs npm && rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.22.0
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 f6c8a87aa03b92c4b0bf3d558e28ea03006eb29db78917daec5cfb6ec1046265
ENV CONTROLLER_TOOLS_VERSION v0.14.0

ENV OPERATOR_SDK_VERSION v1.33.0
ENV OPERATOR_SDK_BIN /usr/bin/operator-sdk
ENV KUSTOMIZE_VERSION v5.3.0
ENV OPM_VERSION v1.36.0
ENV OPM_BIN /usr/bin/opm
ENV OS linux
ENV ARCH amd64
ENV GOLANGCI_LINT_VERSION v1.56.2

RUN npm install -g yarn

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

ENV PATH $PATH:/bin:/usr/local/go/bin:/usr/bin/:/home/build/bin/
ENV GOPATH /home/build
ENV GOCACHE /home/build/.cache/go-build
env GOLANGCI_LINT_CACHE /home/build/.cache/golangci-lint
ENV GOENV /home/build/.config/go/env

RUN useradd -u 65532 -ms /bin/bash build

RUN mkdir -p /home/build/src /home/build/bin /home/build/pkg /home/build/build /home/build/.cache /home/build/.local \
    && chmod -R 0777 /home/build

RUN go install sigs.k8s.io/controller-tools/cmd/controller-gen@${CONTROLLER_TOOLS_VERSION} \
    && go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

RUN chown -R 65532:65532 /home/build

COPY uid_entrypoint.sh /home/build/

WORKDIR /home/build/

USER build

ENTRYPOINT [ "./uid_entrypoint.sh" ]

