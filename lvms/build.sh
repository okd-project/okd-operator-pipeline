#!/bin/bash

# Configuration and variable setup
NAMESPACE="lvms"

DATE="2025-11-01-182956"

source ../common.sh

# Image definitions
export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
export IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"
IMG_CLI=$(get_payload_component cli)

## Functions

init() {
    submodule_initialize operator release-${OCP_SHORT}
}

deinit() {
    submodule_reset operator release-${OCP_SHORT}
}

update() {
    submodule_update operator release-${OCP_SHORT} https://github.com/openshift/lvm-operator.git
}

build_containers() {
    podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .
    podman build -t "${IMG_MUST_GATHER}" --build-arg IMG_CLI=$IMG_CLI -f must-gather.Containerfile .
}

push_containers() {
    push_all_images
}

build_bundle() {
    pushd operator
    sed -i "s|quay.io/lvms_dev/lvms-operator:latest|${IMG_OPERATOR}|g" config/manifests/bases/clusterserviceversion.yaml.in
    make bundle OPERATOR_VERSION=${OCP_DATE} IMG=$IMG_OPERATOR MUST_GATHER_IMG=$IMG_MUST_GATHER BUNDLE_IMG=$IMG_BUNDLE \
     "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" OPERATOR_SDK=operator-sdk

    podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
    podman push "${IMG_BUNDLE}"
    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
