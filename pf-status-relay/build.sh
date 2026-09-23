#!/bin/bash

# Configuration and variable setup
NAMESPACE="pf-status-relay"

source ../common.sh

# Image definitions
IMG_OPERATOR=${REGISTRY}/operator:${OCP_DATE}
IMG_RELAY=${REGISTRY}/relay:${OCP_DATE}
IMG_BUNDLE=${REGISTRY}/bundle:${OCP_DATE}

## Functions

init() {
    submodule_initialize operator release-${OCP_SHORT}
    submodule_initialize relay release-${OCP_SHORT}
}

deinit() {
    submodule_reset operator release-${OCP_SHORT}
    submodule_reset relay release-${OCP_SHORT}
}

update() {
    submodule_update operator release-${OCP_SHORT} https://github.com/openshift/pf-status-relay-operator.git
    submodule_update relay release-${OCP_SHORT} https://github.com/openshift/pf-status-relay.git
}

build_containers() {
    podman build --build-arg CI_VERSION=${OCP_DATE} --build-arg OKD_SHORT=${OCP_SHORT} -t $IMG_OPERATOR -f operator.Containerfile operator
    podman build --build-arg CI_VERSION=${OCP_DATE} --build-arg OKD_SHORT=${OCP_SHORT} -t $IMG_RELAY -f relay.Containerfile relay
    true
}

push_containers() {
    push_all_images
    true
}

build_bundle() {
    convert_all_images_to_digest

    pushd operator

    CSV_BASE="config/manifests/bases/pf-status-relay-operator.clusterserviceversion.yaml"
    CSV="bundle/manifests/pf-status-relay-operator.clusterserviceversion.yaml"

    yq e -i ".spec.template.spec.containers[0].env[0].value = \"${IMG_RELAY}\"" config/manager/env_patch.yaml
    export OLM_SKIP_RANGE=">=4.3.0-0 <${OCP_DATE}"
    yq e -i '.metadata.annotations["olm.skipRange"] = strenv(OLM_SKIP_RANGE)' "${CSV_BASE}"

    make bundle VERSION=${OCP_DATE} IMG=${IMG_OPERATOR} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" BUNDLE_IMG=${IMG_BUNDLE} RELAY_IMG=${IMG_RELAY}

    # PF_STATUS_RELAY_IMAGE lacks the RELATED_IMAGE_ prefix, so operator-sdk does not list it.
    export IMG_RELAY
    yq e -i '.spec.relatedImages += [{"name": "pf-status-relay", "image": strenv(IMG_RELAY)}]' "${CSV}"

    podman build -f bundle.Dockerfile -t ${IMG_BUNDLE} .
    podman push ${IMG_BUNDLE}

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
