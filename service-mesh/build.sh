#!/bin/bash

NAMESPACE="service-mesh"
MAJOR=3
MINOR=0

source ../common.sh

IMG_OPERATOR=${REGISTRY}/operator:${OCP_DATE}
IMG_KIALI_OPERATOR=${REGISTRY}/kiali-operator:${OCP_DATE}
IMG_KIALI=${REGISTRY}/kiali:${OCP_DATE}
IMG_KIALI_CONSOLE_PLUGIN=${REGISTRY}/kiali-console-plugin:${OCP_DATE}
IMG_ISTIO_PROXYV2=${REGISTRY}/istio-proxyv2:${OCP_DATE}
IMG_ISTIO_PILOT=${REGISTRY}/istio-pilot:${OCP_DATE}
IMG_ISTIO_CNI=${REGISTRY}/istio-cni:${OCP_DATE}
IMG_ISTIO_ZTUNNEL=${REGISTRY}/istio-ztunnel:${OCP_DATE}
IMG_ISTIO_MUST_GATHER=${REGISTRY}/istio-must-gather:${OCP_DATE}

IMG_BUNDLE=${REGISTRY}/operator-bundle:${OCP_DATE}

## Build container images
podman build -t ${IMG_OPERATOR} -f operator.Containerfile .
podman build -t ${IMG_KIALI_OPERATOR} -f kiali-operator.Containerfile .
podman build -t ${IMG_KIALI} -f kiali.Containerfile .
podman build -t ${IMG_KIALI_CONSOLE_PLUGIN} -f kiali-console-plugin.Containerfile .
podman build -t ${IMG_ISTIO_PROXYV2} --build-arg SHORT_VERSION=3.0 --build-arg VERSION=${OCP_DATE} -f istio-proxyv2.Containerfile ../
podman build -t ${IMG_ISTIO_PILOT} -f istio-pilot.Containerfile .
podman build -t ${IMG_ISTIO_CNI} -f istio-cni.Containerfile .
podman build -t ${IMG_ISTIO_ZTUNNEL} -f istio-ztunnel.Containerfile .
podman build -t ${IMG_ISTIO_MUST_GATHER} -f istio-must-gather.Containerfile .

push_all_images

# Build operator bundle image
pushd operator

make bundle VERSION=${OCP_DATE} VERSIONS_YAML_FILE=versions.ossm.yaml BUILD_WITH_CONTAINER=0 "BUNDLE_METADATA_OPTS=$BUNDLE_METADATA_OPTS" IMAGE=$IMG_OPERATOR OPERATOR_NAME=servicemeshoperator3
#
podman build -t ${IMG_BUNDLE} -f bundle.Dockerfile .
podman push ${IMG_BUNDLE}

popd
