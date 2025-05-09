#!/bin/bash

set -e -x

source ../common.sh

REGISTRY="${BASE_REGISTRY}/lvms"
REGISTRY_NAMESPACE="lvms"

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"

apply_patch operator release-${OCP_SHORT}

# Build the lvms-operator image
podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .
podman push "${IMG_OPERATOR}"

# Build the lvms-operator bundle image
pushd operator
make bundle OPERATOR_VERSION=${OCP_DATE} IMAGE_REGISTRY=${BASE_REGISTRY} REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE} \
 MUST_GATHER_IMAGE_NAME=must-gather IMAGE_TAG=${OCP_DATE} IMAGE_NAME=operator "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}"
make bundle-build IMAGE_BUILD_CMD=podman OPERATOR_VERSION=${OCP_DATE} IMAGE_REGISTRY=${BASE_REGISTRY} \
  REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE} IMAGE_NAME=operator IMAGE_TAG=${OCP_DATE}
popd

podman build -t "${IMG_MUST_GATHER}" -f must-gather.Containerfile .
podman push "${IMG_MUST_GATHER}"
pushd operator
make bundle-push IMAGE_BUILD_CMD=podman OPERATOR_VERSION=${OCP_DATE} IMAGE_REGISTRY=${BASE_REGISTRY} \
  REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE} IMAGE_NAME=operator IMAGE_TAG=${OCP_DATE}
popd