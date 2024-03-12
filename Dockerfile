FROM quay.io/centos/centos:stream9

# gcc for cgo
RUN dnf -y makecache && \
    dnf -y update && \
    rpm --setcaps shadow-utils 2>/dev/null && \
    dnf install -y which git gcc make unzip diffutils nodejs npm podman fuse-overlayfs --exclude container-selinux && \
    dnf -y clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# Start Podman Adaption
# https://github.com/containers/podman/blob/main/contrib/podmanimage/stable/Containerfile
ARG _REPO_URL="https://raw.githubusercontent.com/containers/image_build/main/podman/stable"
ADD $_REPO_URL/containers.conf /etc/containers/containers.conf
ADD $_REPO_URL/podman-containers.conf /home/build/.config/containers/containers.conf

# Copy & modify the defaults to provide reference if runtime changes needed.
# Changes here are required for running with fuse-overlay storage inside container.
RUN sed -i -e 's|^#mount_program|mount_program|g' \
           -e '/additionalimage.*/a "/var/lib/shared",' \
           -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
           /etc/containers/storage.conf && \
           chmod 644 /etc/containers/containers.conf
# End Podman Adaption


ENV GOLANG_VERSION 1.21.7
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 13b76a9b2a26823e53062fa841b07087d48ae2ef2936445dc34c4ae03293702c
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

RUN useradd -u 65532 -ms /bin/bash build && \
    usermod --add-subuids 100000-165535 --add-subgids 100000-165535 build

RUN mkdir -p /home/build/src /home/build/bin /home/build/pkg /home/build/build /home/build/.cache /home/build/.local/share/containers \
    && chmod -R 0777 /home/build

RUN go install sigs.k8s.io/controller-tools/cmd/controller-gen@${CONTROLLER_TOOLS_VERSION} \
    && go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

RUN chown -R 65532:65532 /home/build


# Podman setup taken from https://www.redhat.com/sysadmin/rootless-podman-jenkins-openshift
RUN  chmod u-s /usr/bin/new[gu]idmap && \
    setcap cap_setuid+eip /usr/bin/newuidmap && \
    setcap cap_setgid+eip /usr/bin/newgidmap && \
    rm -f /var/logs/*

WORKDIR /home/build/

VOLUME /home/build/.local/share/containers


USER build