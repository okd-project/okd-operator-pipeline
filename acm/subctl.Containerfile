FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

ARG CI_VERSION
ARG CI_REVISION

ENV COMPONENT_NAME=subctl \
COMPONENT_VERSION=$CI_VERSION \
DEFAULT_REPO=quay.io/okderators/acm \
IMAGE_NAME_EXTENSION="-rhel9" \
GO111MODULE=on \
GOFLAGS="-mod=vendor -p=4" \
GOCACHE=$HOME/gomod \
GOMODCACHE=$HOME/gomod/pkg/mod \
GOPATH=$HOME/gomod \
GOEXPERIMENT=strictfipsruntime \
BUILD_TAGS="strictfipsruntime"

COPY --chown=default subctl .

# DEBUG
RUN echo CI_CONTAINER_VERSION="$CI_VERSION" && \
    echo CI_VERSION="$CI_VERSION" && \
    echo CI_UPSTREAM_COMMIT="$CI_REVISION" && \
    echo CI_UPSTREAM_VERSION="$CI_VERSION" && \
    go env

# build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p bin dist && \
    export GOARCH="$(go env GOARCH)" && \
    case ${GOARCH} in \
        'amd64' ) os_list=( 'linux' 'windows' 'darwin' ) ;; \
        * ) os_list=( 'linux' ) ;; \
    esac && \
    for target in ${os_list[*]}; do \
        export GOOS="${target}" GOEXE="" && \
        if [[ "${GOOS}" == "windows" ]]; then export GOEXE=".exe"; fi && \
        go build -mod=mod --ldflags "-s -w \
            -X=github.com/submariner-io/subctl/pkg/version.Version=${COMPONENT_VERSION} \
            -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultRepo=${DEFAULT_REPO} \
            -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultSubmarinerOperatorVersion=${COMPONENT_VERSION} \
            -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultSubmarinerVersion=${COMPONENT_VERSION} \
            -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultLighthouseVersion=${COMPONENT_VERSION} \
            -X=github.com/submariner-io/submariner-operator/pkg/names.NettestImage=nettest${IMAGE_NAME_EXTENSION}" \
            --tags non_deploy -o "bin/subctl-${COMPONENT_VERSION}-${GOOS}-${GOARCH}${GOEXE}" ./cmd && \
        tar -cJf "dist/subctl-${COMPONENT_VERSION}-${GOOS}-${GOARCH}${GOEXE}.tar.xz" --transform "s/^bin/subctl-${COMPONENT_VERSION}/" "bin/subctl-${COMPONENT_VERSION}-${GOOS}-${GOARCH}${GOEXE}"; \
	done

#-----------------------------------------------------------------------------------------------#

FROM registry.access.redhat.com/ubi9/ubi:latest AS packager

RUN dnf -y --setopt=install_weak_deps=0 --nodocs \
    --installroot /output install \
    glibc coreutils-single openssl-libs \
 && dnf clean all --installroot /output
RUN [ -d /usr/share/buildinfo ] && cp -a /usr/share/buildinfo /output/usr/share/buildinfo ||:
RUN [ -d /root/buildinfo ] && cp -a /root/buildinfo /output/root/buildinfo ||:

FROM scratch

ARG CI_VERSION

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

COPY --from=packager /output /
COPY --from=builder $REMOTE_SOURCE_DIR/dist /dist/
COPY --from=builder $REMOTE_SOURCE_DIR/bin /usr/local/bin/
COPY --from=builder $REMOTE_SOURCE_DIR/LICENSE /licenses/

RUN ARCH=$(if [ "$(arch)" == "x86_64" ]; then echo "amd64"; elif [ "$(arch)" == "aarch64" ]; then echo "arm64"; else echo $(arch); fi) && \
    ln /usr/local/bin/subctl-${CI_VERSION}-linux-${ARCH} /usr/bin/subctl

LABEL summary="subctl" \
      io.k8s.display-name="subctl" \
      io.k8s.description="subctl" \
      maintainer="maintainers@okd.io" \
      description="subctl"
