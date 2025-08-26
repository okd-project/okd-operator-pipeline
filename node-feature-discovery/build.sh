#!/bin/bash

NAMESPACE="node-feature-discovery"

source ../common.sh

REGISTRY="${BASE_REGISTRY}/node-feature-discovery"

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_NFD="${REGISTRY}/daemon:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

submodule_initialize nfd release-${OCP_SHORT}
submodule_initialize operator release-${OCP_SHORT}

## Build the images
podman build -f operator/Dockerfile -t ${IMG_OPERATOR} operator
podman build -f nfd/Dockerfile --build-arg VERSION=${OCP_DATE} -t ${IMG_NFD} nfd

push_all_images

# Create the bundle
pushd operator

yq e -i "with((select(.kind == \"Deployment\") | .spec.template.spec.containers[0]) ;
 .env |= map(select(.name == \"NODE_FEATURE_DISCOVERY_IMAGE\").value = \"${IMG_NFD}\")
)" config/manager/manager.yaml
yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\"" config/manifests/bases/nfd.clusterserviceversion.yaml

make bundle \
"BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
IMAGE_TAG=${IMG_OPERATOR} \
BUNDLE_IMG=${IMG_BUNDLE} \
VERSION=${OCP_DATE}

podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
podman push "${IMG_BUNDLE}"

popd

submodule_reset nfd release-${OCP_SHORT}
submodule_reset operator release-${OCP_SHORT}
