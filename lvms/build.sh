#!/bin/bash

NAMESPACE="lvms"

source ../common.sh

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

submodule_initialize operator release-${OCP_SHORT}

# Build the lvms-operator image
podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .
podman build -t "${IMG_MUST_GATHER}" -f must-gather.Containerfile .

push_all_images

# Build the lvms-operator bundle image
pushd operator
# Replace containerImage annotation
sed -i "s|quay.io/lvms_dev/lvms-operator:latest|${IMG_OPERATOR}|g" config/manifests/bases/clusterserviceversion.yaml.in
make bundle OPERATOR_VERSION=${OCP_DATE} IMG=$IMG_OPERATOR MUST_GATHER_IMG=$IMG_MUST_GATHER BUNDLE_IMG=$IMG_BUNDLE \
 "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}"

podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
podman push "${IMG_BUNDLE}"
popd

submodule_reset operator release-${OCP_SHORT}