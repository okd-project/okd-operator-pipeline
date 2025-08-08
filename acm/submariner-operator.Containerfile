FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION
ARG CI_REVISION

ENV COMPONENT_NAME=submariner-operator \
COMPONENT_VERSION=$CI_VERSION \
DEFAULT_REPO=quay.io/okderators/acm \
IMAGE_NAME_EXTENSION="-rhel9" \
GO111MODULE=on \
GOFLAGS="-p=4" \
GOCACHE=$HOME/gomod \
GOMODCACHE=$HOME/gomod/pkg/mod \
GOPATH=$HOME/gomod \
GOEXPERIMENT=strictfipsruntime \
BUILD_TAGS="strictfipsruntime"

COPY --chown=default acm/submariner-operator acm/submariner-operator
COPY --chown=default .git .git

WORKDIR $HOME/acm/submariner-operator

# DEBUG
RUN echo CI_CONTAINER_VERSION="$CI_VERSION" && \
    echo CI_VERSION="$CI_VERSION" && \
    echo CI_UPSTREAM_COMMIT="$CI_REVISION" && \
    echo CI_UPSTREAM_VERSION="$CI_VERSION" && \
    go env

# install controller-gen
RUN mkdir -p bin && cd tools && \
    go build -o ../bin/controller-gen sigs.k8s.io/controller-tools/cmd/controller-gen

# generate embedded yamls
RUN bin/controller-gen object:headerFile="hack/boilerplate.go.txt,year=$(date +"%Y")" paths="./..."
RUN bin/controller-gen crd:crdVersions=v1 paths="./..." output:crd:artifacts:config=deploy/crds

#RUN cd vendor/github.com/submariner-io/submariner && ../../../../bin/controller-gen crd:crdVersions=v1 paths="./..." output:crd:artifacts:config=../../../../deploy/submariner/crds
RUN bin/controller-gen crd:crdVersions=v1 paths="github.com/submariner-io/submariner/pkg/apis/..." output:crd:artifacts:config=deploy/submariner/crds

RUN go generate pkg/embeddedyamls/generate.go

# build
RUN go build --ldflags "-s -w \
    -X=main.version=${COMPONENT_VERSION} \
    -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultRepo=${DEFAULT_REPO} \
    -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultSubmarinerOperatorVersion=${COMPONENT_VERSION} \
    -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultSubmarinerVersion=${COMPONENT_VERSION} \
    -X=github.com/submariner-io/submariner-operator/api/v1alpha1.DefaultLighthouseVersion=${COMPONENT_VERSION} \
    -X=github.com/submariner-io/submariner-operator/pkg/names.GatewayImage=submariner-gateway${IMAGE_NAME_EXTENSION} \
    -X=github.com/submariner-io/submariner-operator/pkg/names.RouteAgentImage=submariner-route-agent${IMAGE_NAME_EXTENSION} \
    -X=github.com/submariner-io/submariner-operator/pkg/names.GlobalnetImage=submariner-globalnet${IMAGE_NAME_EXTENSION} \
    -X=github.com/submariner-io/submariner-operator/pkg/names.ServiceDiscoveryImage=lighthouse-agent${IMAGE_NAME_EXTENSION} \
    -X=github.com/submariner-io/submariner-operator/pkg/names.LighthouseCoreDNSImage=lighthouse-coredns${IMAGE_NAME_EXTENSION} \
    -X=github.com/submariner-io/submariner-operator/pkg/names.OperatorImage=submariner${IMAGE_NAME_EXTENSION}-operator \
    -X=github.com/submariner-io/submariner-operator/pkg/names.MetricsProxyImage=nettest${IMAGE_NAME_EXTENSION} \
    -X=github.com/submariner-io/submariner-operator/pkg/names.NettestImage=nettest${IMAGE_NAME_EXTENSION}" \
    -tags strictfipsruntime \
    -o bin/submariner-operator ./cmd

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf -y update && \
    microdnf -y install --nodocs shadow-utils && \
    microdnf clean all

ENV REMOTE_SOURCE_DIR=/opt/app-root/src/acm/submariner-operator/

COPY --from=builder $REMOTE_SOURCE_DIR/bin/submariner-operator /usr/local/bin/submariner-operator

RUN chmod a+x /usr/local/bin/submariner-operator

RUN mkdir /licenses

COPY --from=builder $REMOTE_SOURCE_DIR/LICENSE /licenses/

ENTRYPOINT ["/usr/local/bin/submariner-operator"]

LABEL summary="submariner-operator" \
      io.k8s.display-name="submariner-operator" \
      io.k8s.description="submariner-operator" \
      maintainer="maintainers@okd.io" \
      description="submariner-operator"
