#!/bin/bash

NAMESPACE="vertical-pod-autoscaler"

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_VPA="${REGISTRY}/vertical-pod-autoscaler:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

CSV_BASE="config/manifests/bases/vertical-pod-autoscaler.clusterserviceversion.yaml"
CSV_BUNDLE="bundle/manifests/vertical-pod-autoscaler.clusterserviceversion.yaml"

## Functions

init() {
    submodule_initialize operator release-${OCP_SHORT}
    submodule_initialize autoscaler release-${OCP_SHORT}
}

deinit() {
    submodule_reset operator release-${OCP_SHORT}
    submodule_reset autoscaler release-${OCP_SHORT}
}

update() {
    submodule_update operator release-${OCP_SHORT} https://github.com/openshift/vertical-pod-autoscaler-operator.git
    submodule_update autoscaler release-${OCP_SHORT} https://github.com/openshift/kubernetes-autoscaler.git
}

build_containers() {
    podman build --build-arg VERSION=${OCP_DATE} -t "${IMG_OPERATOR}" -f operator.Containerfile .
    podman build -t "${IMG_VPA}" -f vertical-pod-autoscaler.Containerfile .
}

push_containers() {
    push_all_images
}

build_bundle() {
    # The operand is referenced via the VPA_OPERAND_IMAGE env var (not
    # RELATED_IMAGE_*), so operator-sdk --use-image-digests cannot pin it;
    # convert everything to digests up front instead
    convert_all_images_to_digest

    pushd operator

    # Make automated scaling explicit in the console example (Auto is the CRD
    # default, but showing it makes the fully-automated mode discoverable)
    yq e -i '.spec.updatePolicy.updateMode = "Auto"' config/samples/autoscaling_v1_verticalpodautoscaler.yaml

    export ICON="$(base64 -w 0 ../../icon.png)"
    yq e -i '.metadata.annotations.containerImage = env(IMG_OPERATOR)' "${CSV_BASE}"
    yq e -i '.metadata.annotations.support = "OKD Community"' "${CSV_BASE}"
    yq e -i '.spec.provider.name = "OKD Community"' "${CSV_BASE}"
    yq e -i '.spec.icon[0].base64data = env(ICON)' "${CSV_BASE}"
    yq e -i '.spec.icon[0].mediatype = "image/png"' "${CSV_BASE}"
    export OLM_SKIP_RANGE=">=4.5.0 <${OCP_DATE}"
    yq e -i '.metadata.annotations["olm.skipRange"] = strenv(OLM_SKIP_RANGE)' "${CSV_BASE}"
    export OLM_PROPERTIES="[{\"type\":\"olm.maxOpenShiftVersion\",\"value\":\"${MAJOR}.$((MINOR + 1))\"}]"
    yq e -i '.metadata.annotations["olm.properties"] = strenv(OLM_PROPERTIES)' "${CSV_BASE}"

    make bundle \
        "BUNDLE_METADATA_OPTS=--channels=${CHANNEL} --default-channel=${DEFAULT_CHANNEL}" \
        OPERATOR_IMG="${IMG_OPERATOR}" \
        OPERAND_IMG="${IMG_VPA}" \
        OPERATOR_VERSION="${OCP_DATE}"

    # No RELATED_IMAGE_* env vars exist for operator-sdk to detect, so append
    # the related images it cannot discover from the deployment spec
    export EXTRA_IMAGES="[{\"name\":\"vertical-pod-autoscaler-operator\",\"image\":\"${IMG_OPERATOR}\"},{\"name\":\"vertical-pod-autoscaler\",\"image\":\"${IMG_VPA}\"}]"
    yq e -i '.spec.relatedImages += env(EXTRA_IMAGES)' "${CSV_BUNDLE}"

    make bundle-build CONTAINER_TOOL=podman BUNDLE_IMG="${IMG_BUNDLE}"
    podman push "${IMG_BUNDLE}"

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
