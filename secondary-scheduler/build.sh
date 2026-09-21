#!/bin/bash

NAMESPACE="secondary-scheduler"

# The secondary scheduler operator is versioned independently of the OCP
# release (1.5.x targets OCP 4.21) while its submodule tracks OCP release branches
MAJOR=1
MINOR=5

source ../common.sh

# Submodule branch follows the OKD release, not the operator version
OCP_RELEASE="$(echo "${OKD_VERSION}" | cut -d. -f1-2)"
OCP_BRANCH="release-${OCP_RELEASE}"
OCP_NEXT="$(echo "${OKD_VERSION}" | cut -d. -f1).$(($(echo "${OKD_VERSION}" | cut -d. -f2) + 1))"

# The operand (the secondary scheduler itself) is supplied by the user via
# SecondaryScheduler.spec.schedulerImage, so the operator is the only image built
export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

CSV="operator/manifests/cluster-secondary-scheduler-operator.clusterserviceversion.yaml"
ANNOTATIONS="operator/metadata/annotations.yaml"

## Functions

init() {
    submodule_initialize operator ${OCP_BRANCH}
}

deinit() {
    submodule_reset operator ${OCP_BRANCH}
}

update() {
    submodule_update operator ${OCP_BRANCH} https://github.com/openshift/secondary-scheduler-operator.git
}

build_containers() {
    podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .
}

push_containers() {
    push_all_images
}

build_bundle() {
    # Upstream has no operator-sdk bundle target; the bundle is the committed
    # manifests/ + metadata/ directories, so pin digests manually and edit the
    # CSV in place before building the bundle image
    convert_all_images_to_digest

    export ICON="$(base64 -w 0 ../icon.png)"
    export CSV_NAME="secondaryscheduleroperator.v${OCP_DATE}"
    export CSV_VERSION="${OCP_DATE}"
    export STATUS_DESCRIPTORS="secondary-scheduler-operator.v${OCP_DATE}"
    export CREATED_AT="$(date -I)"

    yq e -i '.metadata.name = strenv(CSV_NAME)' "${CSV}"
    yq e -i '.spec.version = strenv(CSV_VERSION)' "${CSV}"
    yq e -i '.spec.labels["olm-status-descriptors"] = strenv(STATUS_DESCRIPTORS)' "${CSV}"
    yq e -i '.metadata.annotations.containerImage = env(IMG_OPERATOR)' "${CSV}"
    yq e -i '.metadata.annotations.createdAt = strenv(CREATED_AT)' "${CSV}"
    yq e -i '.metadata.annotations.support = "OKD Community"' "${CSV}"
    yq e -i '.spec.provider.name = "OKD Community"' "${CSV}"
    yq e -i '.spec.icon[0].base64data = env(ICON)' "${CSV}"
    yq e -i '.spec.icon[0].mediatype = "image/png"' "${CSV}"
    export OLM_SKIP_RANGE=">=1.0.0 <${OCP_DATE}"
    yq e -i '.metadata.annotations["olm.skipRange"] = strenv(OLM_SKIP_RANGE)' "${CSV}"
    export OLM_PROPERTIES="[{\"type\":\"olm.maxOpenShiftVersion\",\"value\":\"${OCP_NEXT}\"}]"
    yq e -i '.metadata.annotations["olm.properties"] = strenv(OLM_PROPERTIES)' "${CSV}"

    # Upstream RH releases are not published for OKD, so the upgrade graph
    # starts from scratch
    yq e -i 'del(.spec.replaces)' "${CSV}"
    yq e -i 'del(.spec.skips)' "${CSV}"

    yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].image = env(IMG_OPERATOR)' "${CSV}"
    yq e -i '.spec.relatedImages |= map(select(.name == "secondary-scheduler-operator").image = env(IMG_OPERATOR))' "${CSV}"

    yq e -i ".annotations[\"operators.operatorframework.io.bundle.channels.v1\"] = \"${CHANNEL}\"" "${ANNOTATIONS}"
    yq e -i ".annotations[\"operators.operatorframework.io.bundle.channel.default.v1\"] = \"${DEFAULT_CHANNEL}\"" "${ANNOTATIONS}"

    podman build \
        --label "operators.operatorframework.io.bundle.channels.v1=${CHANNEL}" \
        --label "operators.operatorframework.io.bundle.channel.default.v1=${DEFAULT_CHANNEL}" \
        -t "${IMG_BUNDLE}" -f bundle.Containerfile .
    podman push "${IMG_BUNDLE}"
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
