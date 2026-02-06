FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default .git/ .git/

COPY --chown=default metallb/metallb metallb/metallb

WORKDIR $HOME/metallb/metallb/frr-tools/metrics
RUN CGO_ENABLED=0 GO111MODULE=on go build -mod=vendor -o ./frr-metrics

WORKDIR $HOME/metallb/metallb/frr-tools/cp-tool
RUN CGO_ENABLED=0 GO111MODULE=on go build -mod=vendor -o ./cp-tool

WORKDIR $HOME/metallb/metallb/controller
RUN export SOURCE_GIT_COMMIT="${SOURCE_GIT_COMMIT:-$(git rev-parse --verify 'HEAD^{commit}')}" && \
    export GIT_BRANCH="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}" && \
    CGO_ENABLED=0 GO111MODULE=on go build -mod=vendor -o ./controller \
    -ldflags "-X go.universe.tf/metallb/internal/version.gitCommit=${SOURCE_GIT_COMMIT} \
    -X go.universe.tf/metallb/internal/version.gitBranch=${GIT_BRANCH}"

WORKDIR $HOME/metallb/metallb/speaker
RUN export SOURCE_GIT_COMMIT="${SOURCE_GIT_COMMIT:-$(git rev-parse --verify 'HEAD^{commit}')}" && \
    export GIT_BRANCH="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}" && \
    CGO_ENABLED=0 GO111MODULE=on go build -mod=vendor -o ./speaker \
    -ldflags "-X go.universe.tf/metallb/internal/version.gitCommit=${SOURCE_GIT_COMMIT} \
    -X go.universe.tf/metallb/internal/version.gitBranch=${GIT_BRANCH}"

FROM quay.io/centos/centos:stream9

ARG BUILD_SRC=/opt/app-root/src

COPY --from=builder $BUILD_SRC/metallb/metallb/controller/controller \
    $BUILD_SRC/metallb/metallb/speaker/speaker \
    $BUILD_SRC/metallb/metallb/frr-tools/reloader/frr-reloader.sh \
    $BUILD_SRC/metallb/metallb/frr-tools/metrics/frr-metrics \
    $BUILD_SRC/metallb/metallb/frr-tools/cp-tool/cp-tool /

# When running as non root and building in an environment that `umask` masks out
# '+x' for others, it won't be possible to execute. Make sure all can execute,
# just in case
RUN chmod a+x /frr-reloader.sh

LABEL io.k8s.display-name="Metallb" \
    io.k8s.description="This is a component of OKD and provides a metallb plugin."
