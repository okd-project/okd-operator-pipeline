# To test this locally...
# In the directory containing this file, clone the operator project
# as app:
#     git clone https://github.com/submariner-io/submariner-operator app
# Populate vendor:
#     (cd app && go mod vendor)
# Build the container images:
#     docker build . -f Dockerfile.in
# For a full build this needs RHEL entitlements, but you'll be able to
# at least verify the Go build and examine the resulting artifact:
# from the build log, get the container id just before the FROM step
# involving ubi-minimal; then
#     docker run -it --rm <imageid>
# will give you a shell with access to the operator binaries that
# were just built.

FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.submariner-operator.cached Dockerfile.submariner-operator.cached
RUN /dockerfile-drifter.sh package/Dockerfile.submariner-operator Dockerfile.submariner-operator.cached


#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

# Dummy copy command to force execution of drifter
COPY --from=drifter $REMOTE_SOURCE_DIR/app/Dockerfile.submariner-operator.cached /tmp/Dockerfile.submariner-operator.cached

ENV COMPONENT_NAME=submariner-operator \
COMPONENT_VERSION=v0.20.1 \
DEFAULT_REPO=registry.redhat.io/rhacm2 \
IMAGE_NAME_EXTENSION="-rhel9" \
GO111MODULE=on \
#GOFLAGS="-mod=vendor -p=4" \
GOFLAGS="-p=4" \
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
    echo CI_UPSTREAM_COMMIT="ee33bdf5cc655b22267fbb9b7015dab8b4a68609" && \
    echo CI_UPSTREAM_VERSION="0.20.1" && \
    go env

# install controller-gen
#RUN mkdir -p bin && cd tools && \
#    go mod vendor && \
#    go build -o ../bin/controller-gen sigs.k8s.io/controller-tools/cmd/controller-gen
RUN source $CACHITO_ENV_FILE && \
    mkdir -p bin && cd tools && \
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

#-----------------------------------------------------------------------------------------------#


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf -y update && \
    microdnf -y install --nodocs shadow-utils && \
    microdnf clean all

RUN adduser -r -l -u 1001010000 submariner

COPY --from=builder $REMOTE_SOURCE_DIR/app/bin/submariner-operator /usr/local/bin/submariner-operator

RUN chown -R submariner:submariner /usr/local/bin/submariner-operator && \
    chmod a+x /usr/local/bin/submariner-operator

RUN mkdir /licenses

COPY --from=builder $REMOTE_SOURCE_DIR/app/LICENSE /licenses/

USER 1001010000

ENTRYPOINT ["/usr/local/bin/submariner-operator"]

LABEL com.redhat.component="submariner-operator-container" \
      name="rhacm2/submariner-rhel9-operator" \
      version="v0.20.1" \
      com.github.url="https://github.com/submariner-io/submariner-operator.git" \
      com.github.commit="ee33bdf5cc655b22267fbb9b7015dab8b4a68609" \
      summary="submariner-operator" \
      io.openshift.expose-services="" \
      io.openshift.tags="submariner,submariner-operator,rhel9" \
      io.openshift.wants="submariner-gateway,submariner-route-agent,submariner-globalnet,lighthouse-agent,lighthouse-coredns" \
      io.openshift.non-scalable="true" \
      io.k8s.display-name="submariner-operator" \
      io.k8s.description="submariner-operator" \
      maintainer="['multi-cluster-networking@redhat.com']" \
      description="submariner-operator"
