#!/bin/bash

NAMESPACE="devworkspace"
MAJOR=0
MINOR=40

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_PROJECT_CLONE="${REGISTRY}/project-clone:${OCP_DATE}"
export IMG_PROJECT_BACKUP="${REGISTRY}/project-backup:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

## Functions

init() {
    submodule_initialize operator 0.${MINOR}.x
}

deinit() {
    submodule_reset operator 0.${MINOR}.x
}

update() {
    submodule_update operator 0.${MINOR}.x https://github.com/devfile/devworkspace-operator.git
}

build_containers() {
    podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .
    podman build -t "${IMG_PROJECT_CLONE}" -f project-clone.Containerfile .
    podman build -t "${IMG_PROJECT_BACKUP}" -f project-backup.Containerfile .
}

push_containers() {
    push_all_images
}

build_bundle() {
    convert_all_images_to_digest

    pushd operator

    # The devworkspace PROJECT uses go.kubebuilder.io/v2 which operator-sdk >= v1.15
    # no longer supports, so we cannot regenerate the bundle via make generate_olm_bundle_yaml.
    # Instead, update the pre-generated CSV that ships in the repo with our image digests,
    # then build the bundle image using build/bundle.Dockerfile (the Makefile-defined path).

    CSV_PATH="deploy/bundle/manifests/devworkspace-operator.clusterserviceversion.yaml"

    # ── Step 1: Replace upstream image references with OKD digest images ──────
    # sed updates the deployment container image, RELATED_IMAGE_* env vars, and
    # spec.relatedImages in one pass. Images not rebuilt by OKD
    # (pvc_cleanup_job/ubi-micro, async_storage_*) are left unchanged.
    sed -i -E "s|quay.io/devfile/devworkspace-controller:[^ \"']+|${IMG_OPERATOR}|g"  "${CSV_PATH}"
    sed -i -E "s|quay.io/devfile/project-clone:[^ \"']+|${IMG_PROJECT_CLONE}|g"       "${CSV_PATH}"
    sed -i -E "s|quay.io/devfile/project-backup:[^ \"']+|${IMG_PROJECT_BACKUP}|g"     "${CSV_PATH}"

    # ── Step 2: Build and push bundle image ───────────────────────────────────
    podman build -f build/bundle.Dockerfile -t "${IMG_BUNDLE}" .
    podman push "${IMG_BUNDLE}"

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
