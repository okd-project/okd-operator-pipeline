#!/bin/bash

set -e -x

source ../common.sh

REGISTRY="${BASE_REGISTRY}/local-storage"
REGISTRY_NAMESPACE="local-storage"

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_DISKMAKER="${REGISTRY}/diskmaker:${OCP_DATE}"
IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"
IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

apply_patch operator release-${OCP_SHORT}

podman build -t $IMG_OPERATOR -f operator.Containerfile .
podman build -t $IMG_DISKMAKER -f diskmaker.Containerfile .
podman build -t $IMG_MUST_GATHER -f mustgather.Containerfile .

podman push $IMG_OPERATOR
podman push $IMG_DISKMAKER
podman push $IMG_MUST_GATHER

pushd operator

export_image_digest OPERATOR_IMG $IMG_OPERATOR
export_image_digest DISKMAKER_IMG $IMG_DISKMAKER
export KUBE_RBAC_PROXY_IMG=$IMG_KUBE_RBAC_PROXY
export KUBE_RBAC_PROXY_IMAGE=$IMG_KUBE_RBAC_PROXY
export_image_digest MUSTGATHER_IMG $IMG_MUST_GATHER
export VERSION=$OCP_DATE
export ICON="$(base64 -w 0 ../icon.png)"

# Patch
yq e -i ".metadata.name = \"local-storage-operator.v${OCP_DATE}\"" ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.version = env(VERSION)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.metadata.annotations.containerImage = env(OPERATOR_IMG)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.metadata.annotations.support = "OKD Community"' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.description = "Operator that configures local storage volumes for use in OKD. OKD 4.2 and above are the only supported OKD versions."' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.icon[0].base64data = env(ICON)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.icon[0].mediatype = "image/png"' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.provider.name = "OKD Community"' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i ".spec.labels.alm-status-descriptors = \"local-storage-operator.v${OCP_DATE}\"" ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].image = env(OPERATOR_IMG)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].env |= map(select(.name == "KUBE_RBAC_PROXY_IMAGE").value = env(KUBE_RBAC_PROXY_IMG))' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].env |= map(select(.name == "DISKMAKER_IMAGE").value = env(DISKMAKER_IMG))' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].env |= map(select(.name == "MUSTGATHER_IMAGE").value = env(MUSTGATHER_IMG))' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml

pushd config
podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
podman push $IMG_BUNDLE
popd
popd