#!/bin/bash

MAJOR=3
MINOR=0

source ../common.bash

REGISTRY={BASE_REGISTRY}/service-mesh

IMG_OPERATOR=${REGISTRY}/operator:${OCP_DATE}
IMG_KIALI_OPERATOR=${REGISTRY}/kiali-operator:${OCP_DATE}
IMG_KIALI=${REGISTRY}/kiali:${OCP_DATE}
IMG_KIALI_CONSOLE_PLUGIN=${REGISTRY}/kiali-console-plugin:${OCP_DATE}
IMG_ISTIO_PROXYV2=${REGISTRY}/istio-proxyv2:${OCP_DATE}
IMG_ISTIO_PILOT=${REGISTRY}/istio-pilot:${OCP_DATE}
IMG_ISTIO_CNI=${REGISTRY}/istio-cni:${OCP_DATE}
IMG_ISTIO_ZTUNNEL=${REGISTRY}/istio-ztunnel:${OCP_DATE}
IMG_ISTIO_MUST_GATHER=${REGISTRY}/istio-must-gather:${OCP_DATE}


# Build container images
podman build -t ${IMG_OPERATOR} -f operator.Containerfile .
podman build -t ${IMG_KIALI_OPERATOR} -f kiali-operator.Containerfile .
podman build -t ${IMG_KIALI} -f kiali.Containerfile .
podman build -t ${IMG_KIALI_CONSOLE_PLUGIN} -f kiali-console-plugin.Containerfile .
podman build -t ${IMG_ISTIO_PROXYV2} -f istio-proxyv2.Containerfile .
podman build -t ${IMG_ISTIO_PILOT} -f istio-pilot.Containerfile .
podman build -t ${IMG_ISTIO_CNI} -f istio-cni.Containerfile .
podman build -t ${IMG_ISTIO_ZTUNNEL} -f istio-ztunnel.Containerfile .
podman build -t ${IMG_ISTIO_MUST_GATHER} -f istio-must-gather.Containerfile .

# Push container images
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



popd


IMG_BUNDLE=${REGISTRY}/operator-bundle:${OCP_DATE}