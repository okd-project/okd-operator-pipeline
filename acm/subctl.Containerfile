# To test this locally...
# In the directory containing this file, clone the subctl project
# as app:
#     git clone https://github.com/submariner-io/subctl app
# Populate vendor:
#     (cd app && go mod vendor)
# Build the container images:
#     docker build . -f Dockerfile.in
# For a full build this needs RHEL entitlements, but you'll be able to
# at least verify the Go build and examine the resulting artifact:
# from the build log, get the container id just before the FROM step
# involving ubi-minimal; then
#     docker run -it --rm <imageid>
# will give you a shell with access to the subctl binaries that
# were just built.

FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.subctl.cached Dockerfile.subctl.cached
RUN /dockerfile-drifter.sh package/Dockerfile.subctl Dockerfile.subctl.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

# Dummy copy command to force execution of drifter
COPY --from=drifter $REMOTE_SOURCE_DIR/app/Dockerfile.subctl.cached /tmp/Dockerfile.subctl.cached

ENV COMPONENT_NAME=subctl \
COMPONENT_VERSION=v0.20.1 \
DEFAULT_REPO=registry.redhat.io/rhacm2 \
IMAGE_NAME_EXTENSION="-rhel9" \
GO111MODULE=on \
GOFLAGS="-mod=vendor -p=4" \
GOCACHE=$REMOTE_SOURCE_DIR/deps/gomod \
GOMODCACHE=$REMOTE_SOURCE_DIR/deps/gomod/pkg/mod \
GOPATH=$REMOTE_SOURCE_DIR/deps/gomod \
GOEXPERIMENT=strictfipsruntime \
BUILD_TAGS="strictfipsruntime"

# Cachito
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR

WORKDIR $REMOTE_SOURCE_DIR/app

# DEBUG
RUN echo CI_CONTAINER_VERSION="v0.20.1" && \
    echo CI_VERSION="0.20.1" && \
    echo CI_UPSTREAM_COMMIT="8e6690d096571e48b2407f1ee8efd222c21268e6" && \
    echo CI_UPSTREAM_VERSION="0.20.1" && \
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
        go build --ldflags "-s -w \
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


#@follow_tag(registry.redhat.io/ubi9:latest)
FROM registry.redhat.io/ubi9:9.6-1747219013 AS packager

RUN dnf -y --setopt=install_weak_deps=0 --nodocs \
    --installroot /output install \
    glibc coreutils-single openssl-libs \
 && dnf clean all --installroot /output
RUN [ -d /usr/share/buildinfo ] && cp -a /usr/share/buildinfo /output/usr/share/buildinfo ||:
RUN [ -d /root/buildinfo ] && cp -a /root/buildinfo /output/root/buildinfo ||:

FROM scratch

COPY --from=packager /output /
COPY --from=builder $REMOTE_SOURCE_DIR/app/dist /dist/
COPY --from=builder $REMOTE_SOURCE_DIR/app/bin /usr/local/bin/
COPY --from=builder $REMOTE_SOURCE_DIR/app/LICENSE /licenses/

RUN ARCH=$(if [ "$(arch)" == "x86_64" ]; then echo "amd64"; elif [ "$(arch)" == "aarch64" ]; then echo "arm64"; else echo $(arch); fi) && \
    ln /usr/local/bin/subctl-v0.20.1-linux-${ARCH} /usr/bin/subctl

LABEL com.redhat.component="subctl-container" \
      name="rhacm2/subctl-rhel9" \
      version="v0.20.1" \
      com.github.url="https://github.com/submariner-io/subctl.git" \
      com.github.commit="8e6690d096571e48b2407f1ee8efd222c21268e6" \
      summary="subctl" \
      io.openshift.expose-services="" \
      io.openshift.tags="submariner,subctl,rhel9" \
      io.openshift.wants="" \
      io.openshift.non-scalable="true" \
      io.k8s.display-name="subctl" \
      io.k8s.description="subctl" \
      maintainer="['multi-cluster-networking@redhat.com']" \
      description="subctl"
