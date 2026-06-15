#!/bin/bash

# Configuration and variable setup
NAMESPACE="sandboxed-containers"

# The OpenShift sandboxed containers operator (OSC) is independently versioned:
# upstream branches are named osc-release-v<MAJOR>.<MINOR> (not release-<OCP_SHORT>).
# Override MAJOR/MINOR with the operator version to track; OKD_VERSION / payload
# lookups in common.sh stay on the platform version regardless.
export MAJOR=1
export MINOR=13

source ../common.sh

# Upstream release branch to track, e.g. osc-release-v1.12
OSC_BRANCH="osc-release-v${OCP_SHORT}"

# Image definitions
export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_KATA_MONITOR="${REGISTRY}/kata-monitor:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

CSV_BASE="config/manifests/bases/sandboxed-containers-operator.clusterserviceversion.yaml"
MANAGER_YAML="config/manager/manager.yaml"

# kata-monitor builds from the kata-containers source tree vendored by the
# operator submodule (pulled by the recursive cloud-api-adaptor submodule init).
KATA_SRC="operator/config/peerpods/podvm/cloud-api-adaptor/podvm-payload/kata-containers"

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
    # The operator image carries both the manager and metrics-server binaries; the
    # bundle's "controller" and "metrics-server" kustomize images both point at it.
    podman build -t "${IMG_OPERATOR}" -f operator.Containerfile ./operator

    # kata-monitor backs the openshift-sandboxed-containers-monitor DaemonSet the
    # operator creates on the bare-metal Kata path (RELATED_IMAGE_KATA_MONITOR).
    podman build -t "${IMG_KATA_MONITOR}" -f kata-monitor.Containerfile "./${KATA_SRC}"

    # must-gather takes oc and the base gather script from the OKD payload's
    # must-gather image rather than ose-must-gather-rhel9.
    podman build -t "${IMG_MUST_GATHER}" \
        --build-arg "MUST_GATHER_IMAGE=$(get_payload_component must-gather)" \
        -f must-gather.Containerfile ./operator/must-gather
}

push_containers() {
    push_all_images
}

build_bundle() {
    # Digest refs for the RELATED_IMAGE_* env vars written into the deployment
    # spec below (operator-sdk's --use-image-digests only converts IMG itself).
    # Requires the images to be pushed already: init -> build -> push -> bundle.
    convert_all_images_to_digest

    pushd operator

    # Point the bare-metal-path RELATED_IMAGE_* env vars at the OKD images so
    # make bundle generates spec.relatedImages from them. The peer-pods / CoCo
    # images (caa, podvm-*, peerpods-webhook, storage-helper) are not rebuilt
    # for OKD and stay on registry.redhat.io.
    yq e -i '(.spec.template.spec.containers[] | select(.name == "manager") | .env[] | select(.name == "RELATED_IMAGE_KATA_MONITOR") | .value) = env(IMG_KATA_MONITOR)' "${MANAGER_YAML}"
    yq e -i '(.spec.template.spec.containers[] | select(.name == "manager") | .env[] | select(.name == "RELATED_IMAGE_MUST_GATHER") | .value) = env(IMG_MUST_GATHER)' "${MANAGER_YAML}"

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
