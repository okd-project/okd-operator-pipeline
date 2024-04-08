FROM quay.io/centos/centos:stream9

# gcc for cgo
RUN dnf -y makecache && \
#    dnf module -y enable nodejs:20 && \
    dnf config-manager --set-enabled crb && \
    dnf install -y epel-release epel-next-release && \
    dnf -y update && \
    rpm --setcaps shadow-utils 2>/dev/null && \
    dnf install -y which git gcc make unzip diffutils nodejs npm buildah fuse-overlayfs cpp g++ --exclude container-selinux && \
    dnf -y clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# Buildah Adaption
# Setup internal Buildah to pass secrets/subscriptions down from host to internal container
RUN printf '/run/secrets/etc-pki-entitlement:/run/secrets/etc-pki-entitlement\n/run/secrets/rhsm:/run/secrets/rhsm\n' > /etc/containers/mounts.conf

ADD https://raw.githubusercontent.com/containers/image_build/main/buildah/containers.conf /etc/containers/containers.conf

# Copy & modify the defaults to provide reference if runtime changes needed.
# Changes here are required for running with fuse-overlay storage inside container.
RUN sed -e 's|^#mount_program|mount_program|g' \
        -e '/additionalimage.*/a "/var/lib/shared",' \
        -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
        /etc/containers/storage.conf && \
    chmod 644 /etc/containers/storage.conf && \
    chmod 644 /etc/containers/containers.conf

RUN mkdir -p /var/lib/shared/overlay-images \
             /var/lib/shared/overlay-layers \
             /var/lib/shared/vfs-images \
             /var/lib/shared/vfs-layers && \
    touch /var/lib/shared/overlay-images/images.lock && \
    touch /var/lib/shared/overlay-layers/layers.lock && \
    touch /var/lib/shared/vfs-images/images.lock && \
    touch /var/lib/shared/vfs-layers/layers.lock

# Define uid/gid ranges for our user https://github.com/containers/buildah/issues/3053
RUN useradd build -u 65532 && \
    usermod --add-subuids 100000-165535 --add-subgids 100000-165535 build && \
    mkdir -p /home/build/.local/share/containers && \
    mkdir -p /home/build/.config/containers && \
    chown -R build:build /home/build
# See:  https://github.com/containers/buildah/issues/4669
# Copy & modify the config for the `build` user and remove the global
# `runroot` and `graphroot` which current `build` user cannot access,
# in such case storage will choose a runroot in `/var/tmp`.
RUN sed -e 's|^#mount_program|mount_program|g' \
        -e 's|^graphroot|#graphroot|g' \
        -e 's|^runroot|#runroot|g' \
        /etc/containers/storage.conf \
        > /home/build/.config/containers/storage.conf && \
        chown build:build /home/build/.config/containers/storage.conf

VOLUME /var/lib/containers
VOLUME /home/build/.local/share/containers
# End Buildah Adaption

ENV OC_VERSION 4.15.0-0.okd-2024-03-10-010116

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

RUN curl -fsSLo oc.tar.gz "https://github.com/okd-project/okd/releases/download/${OC_VERSION}/openshift-client-${OS}-${OC_VERSION}.tar.gz" \
    && tar -C /usr/bin -xzf oc.tar.gz \
    && rm oc.tar.gz

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
ENV GOLANGCI_LINT_CACHE /home/build/.cache/golangci-lint
ENV GOENV /home/build/.config/go/env

RUN go install sigs.k8s.io/controller-tools/cmd/controller-gen@${CONTROLLER_TOOLS_VERSION} \
    && go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

RUN mkdir -p /home/build/src /home/build/bin /home/build/pkg /home/build/build /home/build/.cache /home/build/.local/share/containers \
    && chmod -R 0777 /home/build \
    && chown -R build:build /home/build

WORKDIR /home/build/

VOLUME /home/build/.local/share/containers

USER build
# Set an environment variable to default to chroot isolation for RUN
# instructions and "buildah run".
ENV BUILDAH_ISOLATION=chroot