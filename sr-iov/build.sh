#!/bin/bash

set -e -x

source ../common.sh

REGISTRY="${BASE_REGISTRY}/sr-iov"
REGISTRY_NAMESPACE="sr-iov"

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_CNI="${REGISTRY}/sriov-cni:${OCP_DATE}"
IMG_IB_CNI="${REGISTRY}/ib-cni:${OCP_DATE}"
IMG_RDMA_CNI="${REGISTRY}/rdma-cni:${OCP_DATE}"
IMG_DP_ADMISSION_CONTROLLER="${REGISTRY}/dp-admission-controller:${OCP_DATE}"
IMG_NETWORK_DEVICE_PLUGIN="${REGISTRY}/network-device-plugin:${OCP_DATE}"
IMG_NETWORK_METRICS_EXPORTER="${REGISTRY}/network-metrics-exporter:${OCP_DATE}"
IMG_NETWORK_CONFIG_DAEMON="${REGISTRY}/network-config-daemon:${OCP_DATE}"
IMG_NETWORK_WEBHOOK="${REGISTRY}/network-webhook:${OCP_DATE}"

IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

BUNDLE_IMG="${REGISTRY}/operator-bundle:${OCP_DATE}"

apply_patch operator release-${OCP_SHORT}
apply_patch cni release-${OCP_SHORT}
apply_patch infiniband-cni release-${OCP_SHORT}

# Build the images
podman build -t "${IMG_OPERATOR}" -f operator.Containerfile ../
podman build -t "${IMG_NETWORK_CONFIG_DAEMON}" -f network-config-daemon.Containerfile ../
podman build -t "${IMG_NETWORK_WEBHOOK}" -f network-webhook.Containerfile ../
podman build -t "${IMG_CNI}" -f sriov-cni.Containerfile .
podman build -t "${IMG_IB_CNI}" -f infiniband-cni.Containerfile .
podman build -t "${IMG_RDMA_CNI}" -f rdma-cni.Containerfile .
podman build -t "${IMG_DP_ADMISSION_CONTROLLER}" -f admission-controller.Containerfile .
podman build -t "${IMG_NETWORK_DEVICE_PLUGIN}" -f network-device-plugin.Containerfile .
podman build -t "${IMG_NETWORK_METRICS_EXPORTER}" -f network-metrics-exporter.Containerfile .

# Push the images
podman push "${IMG_OPERATOR}"
podman push "${IMG_CNI}"
podman push "${IMG_IB_CNI}"
podman push "${IMG_RDMA_CNI}"
podman push "${IMG_DP_ADMISSION_CONTROLLER}"
podman push "${IMG_NETWORK_DEVICE_PLUGIN}"
podman push "${IMG_NETWORK_METRICS_EXPORTER}"
podman push "${IMG_NETWORK_CONFIG_DAEMON}"
podman push "${IMG_NETWORK_WEBHOOK}"

# Build operator bundle

export VERSION=${OCP_DATE}

pushd operator

# Replace image environment variables
yq e -i "with((select(.kind == \"Deployment\") | .spec.template.spec.containers[0]) ;
 .env |= map(select(.name == \"SRIOV_INFINIBAND_CNI_IMAGE\").value = \"${IMG_IB_CNI}\") |
 .env |= map(select(.name == \"SRIOV_CNI_IMAGE\").value = \"${IMG_CNI}\") |
 .env |= map(select(.name == \"RDMA_CNI_IMAGE\").value = \"${IMG_RDMA_CNI}\") |
 .env |= map(select(.name == \"NETWORK_RESOURCES_INJECTOR_IMAGE\").value = \"${IMG_DP_ADMISSION_CONTROLLER}\") |
 .env |= map(select(.name == \"SRIOV_DEVICE_PLUGIN_IMAGE\").value = \"${IMG_NETWORK_DEVICE_PLUGIN}\") |
 .env |= map(select(.name == \"METRICS_EXPORTER_IMAGE\").value = \"${IMG_NETWORK_METRICS_EXPORTER}\") |
 .env |= map(select(.name == \"SRIOV_NETWORK_CONFIG_DAEMON_IMAGE\").value = \"${IMG_NETWORK_CONFIG_DAEMON}\") |
 .env |= map(select(.name == \"SRIOV_NETWORK_WEBHOOK_IMAGE\").value = \"${IMG_NETWORK_WEBHOOK}\") |
 .env |= map(select(.name == \"METRICS_EXPORTER_KUBE_RBAC_PROXY_IMAGE\").value = \"${IMG_KUBE_RBAC_PROXY}\")
)" ./config/manager/manager.yaml
yq e -i ".spec.template.spec.containers[0].image = \"controller:latest\"" ./config/manager/manager.yaml
yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\"" ./config/manifests/bases/sriov-network-operator.clusterserviceversion.yaml

make -f Makefile.bundle bundle IMAGE_BUILDER=podman IMAGE_REPO="${REGISTRY}" CONFIG_DAEMON_IMAGE_TAG="${IMG_NETWORK_CONFIG_DAEMON}" \
 WEBHOOK_IMAGE_TAG="${IMG_NETWORK_WEBHOOK}" VERSION="${OCP_DATE}" IMG="${IMG_OPERATOR}" BUNDLE_IMG="${BUNDLE_IMG}" \
 IMAGE_TAG="${IMG_OPERATOR}"
yq e -i '.spec.labels.olm-status-descriptors = env(VERSION)' bundle/manifests/sriov-network-operator.clusterserviceversion.yaml

# Build and push the bundle image
podman build -t "${BUNDLE_IMG}" -f bundle.Dockerfile .
podman push "${BUNDLE_IMG}"
popd

