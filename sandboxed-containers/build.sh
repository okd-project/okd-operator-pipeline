#!/bin/bash

# Configuration and variable setup
NAMESPACE="sandboxed-containers"

# The OpenShift sandboxed containers operator (OSC) is independently versioned:
# upstream branches are named osc-release-v<MAJOR>.<MINOR> (not release-<OCP_SHORT>).
# Override MAJOR/MINOR with the operator version to track; OKD_VERSION / payload
# lookups in common.sh stay on the platform version regardless.
export MAJOR=1
export MINOR=12

source ../common.sh

# Upstream release branch to track, e.g. osc-release-v1.12
OSC_BRANCH="osc-release-v${OCP_SHORT}"

# Image definitions
export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

CSV_BASE="config/manifests/bases/sandboxed-containers-operator.clusterserviceversion.yaml"

## Functions

init() {
    submodule_initialize operator "${OSC_BRANCH}"
}

deinit() {
    submodule_reset operator "${OSC_BRANCH}"
}

update() {
    submodule_update operator "${OSC_BRANCH}" https://github.com/openshift/sandboxed-containers-operator.git
}

build_containers() {
    # A single image carries both the manager and metrics-server binaries; the
    # bundle's "controller" and "metrics-server" kustomize images both point at it.
    podman build -t "${IMG_OPERATOR}" -f operator.Containerfile ./operator
}

push_containers() {
    push_all_images
}

build_bundle() {
    pushd operator

    # OKD branding on the CSV base
    export ICON="$(base64 -w 0 ../../icon.png)"
    yq e -i '.metadata.annotations.containerImage = env(IMG_OPERATOR)' "${CSV_BASE}"
    yq e -i '.metadata.annotations.support = "OKD Community"' "${CSV_BASE}"
    yq e -i '.spec.provider.name = "OKD Community"' "${CSV_BASE}"
    yq e -i '.spec.icon[0].base64data = env(ICON)' "${CSV_BASE}"
    yq e -i '.spec.icon[0].mediatype = "image/png"' "${CSV_BASE}"

    # make bundle sets both the "controller" and "metrics-server" kustomize images
    # to IMG and lets operator-sdk auto-populate spec.relatedImages. --use-image-digests
    # (from common.sh's BUNDLE_METADATA_OPTS) requires IMG_OPERATOR to be pushed first,
    # which the standard init -> build -> push -> bundle order guarantees.
    make bundle \
        "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
        IMG="${IMG_OPERATOR}" \
        VERSION="${OCP_DATE}"

    podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
    podman push "${IMG_BUNDLE}"

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
