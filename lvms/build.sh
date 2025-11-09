#!/bin/bash

NAMESPACE="lvms"

DATE="2025-11-01-182956"

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
export IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"
IMG_CLI=$(get_payload_component cli)

submodule_initialize operator release-${OCP_SHORT}

# Build the lvms-operator image
podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .
podman build -t "${IMG_MUST_GATHER}" --build-arg IMG_CLI=$IMG_CLI -f must-gather.Containerfile .

push_all_images

# Build the lvms-operator bundle image
pushd operator
# Replace containerImage annotation
sed -i "s|quay.io/lvms_dev/lvms-operator:latest|${IMG_OPERATOR}|g" config/manifests/bases/clusterserviceversion.yaml.in
make bundle OPERATOR_VERSION=${OCP_DATE} IMG=$IMG_OPERATOR MUST_GATHER_IMG=$IMG_MUST_GATHER BUNDLE_IMG=$IMG_BUNDLE \
 "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" OPERATOR_SDK=operator-sdk

podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
podman push "${IMG_BUNDLE}"
popd

submodule_reset operator release-${OCP_SHORT}