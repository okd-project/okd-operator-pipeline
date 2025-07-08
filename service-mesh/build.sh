#!/bin/bash

MAJOR=3
MINOR=0

source ../common.sh

REGISTRY=${BASE_REGISTRY}/service-mesh

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

OLD_TAG=3.0.0-2025-07-02-152941

## Build container images
#podman build -t ${IMG_OPERATOR} -f operator.Containerfile .
#podman build -t ${IMG_KIALI_OPERATOR} -f kiali-operator.Containerfile .
#podman build -t ${IMG_KIALI} -f kiali.Containerfile .
#podman build -t ${IMG_KIALI_CONSOLE_PLUGIN} -f kiali-console-plugin.Containerfile .
#podman build -t ${IMG_ISTIO_PROXYV2} --build-arg SHORT_VERSION=3.0 --build-arg VERSION=${OCP_DATE} -f istio-proxyv2.Containerfile ../
#podman build -t ${IMG_ISTIO_PILOT} -f istio-pilot.Containerfile .
#podman build -t ${IMG_ISTIO_CNI} -f istio-cni.Containerfile .
#podman build -t ${IMG_ISTIO_ZTUNNEL} -f istio-ztunnel.Containerfile .
#podman build -t ${IMG_ISTIO_MUST_GATHER} -f istio-must-gather.Containerfile .
#
podman tag ${REGISTRY}/operator:${OLD_TAG} ${IMG_OPERATOR}
podman tag ${REGISTRY}/kiali-operator:${OLD_TAG} ${IMG_KIALI_OPERATOR}
podman tag ${REGISTRY}/kiali:${OLD_TAG} ${IMG_KIALI}
podman tag ${REGISTRY}/kiali-console-plugin:${OLD_TAG} ${IMG_KIALI_CONSOLE_PLUGIN}
podman tag ${REGISTRY}/istio-proxyv2:${OLD_TAG} ${IMG_ISTIO_PROXYV2}
podman tag ${REGISTRY}/istio-pilot:${OLD_TAG} ${IMG_ISTIO_PILOT}
podman tag ${REGISTRY}/istio-cni:${OLD_TAG} ${IMG_ISTIO_CNI}
podman tag ${REGISTRY}/istio-ztunnel:${OLD_TAG} ${IMG_ISTIO_ZTUNNEL}
podman tag ${REGISTRY}/istio-must-gather:${OLD_TAG} ${IMG_ISTIO_MUST_GATHER}

## Push container images
podman push ${IMG_OPERATOR}
podman push ${IMG_KIALI_OPERATOR}
podman push ${IMG_KIALI}
podman push ${IMG_KIALI_CONSOLE_PLUGIN}
podman push ${IMG_ISTIO_PROXYV2}
podman push ${IMG_ISTIO_PILOT}
podman push ${IMG_ISTIO_CNI}
podman push ${IMG_ISTIO_ZTUNNEL}
podman push ${IMG_ISTIO_MUST_GATHER}


# Build operator bundle image
pushd operator

make bundle VERSION=${OCP_DATE} VERSIONS_YAML_FILE=versions.ossm.yaml BUILD_WITH_CONTAINER=0 "BUNDLE_METADATA_OPTS=$BUNDLE_METADATA_OPTS" IMAGE=$IMG_OPERATOR OPERATOR_NAME=servicemeshoperator3
#
podman build -t ${IMG_BUNDLE} -f bundle.Dockerfile .
podman push ${IMG_BUNDLE}

popd
