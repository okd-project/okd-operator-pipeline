#!/bin/bash

NAMESPACE="ptp"

source ../common.sh

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_CEP="${REGISTRY}/cloud-event-proxy:${OCP_DATE}"
IMG_LPTPD="${REGISTRY}/linuxptpd:${OCP_DATE}"
IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)
IMG_CLI="$(get_payload_component "cli")"
BUNDLE_IMG="${REGISTRY}/operator-bundle:${OCP_DATE}"

init() {
    submodule_initialize operator release-${OCP_SHORT}
}

deinit() {
    submodule_reset operator release-${OCP_SHORT}
}

update() {
    submodule_update operator release-${OCP_SHORT} https://github.com/openshift/ptp-operator.git
}

build_containers() {
    podman build -t "${IMG_OPERATOR}" -f operator.Containerfile ../
    podman build -t "${IMG_CEP}" -f Dockerfile.cep ./operator/ptp-tools/
    podman build -t "${IMG_LPTPD}" -f Dockerfile.lptpd ./operator/ptp-tools/
    podman build -t "${IMG_MUST_GATHER}" -f must-gather.Containerfile --build-arg IMG_CLI=$IMG_CLI
}

push_containers() {
    podman push "${IMG_OPERATOR}"
    podman push "${IMG_CEP}"
    podman push "${IMG_LPTPD}"
    podman push "${IMG_MUST_GATHER}"
}

build_bundle() {
    export ICON="$(base64 -w 0 ../icon.png)"
    export OCP_DATE IMG_OPERATOR IMG_LPTPD IMG_CEP IMG_KUBE_RBAC_PROXY

    pushd operator

    # Patch
    yq e -i ".metadata.name = \"ptp-operator.v${OCP_DATE}\"" ./config/manifests/bases/ptp-operator.clusterserviceversion.yaml
    yq e -i '.spec.version = env(OCP_DATE)' ./config/manifests/bases/ptp-operator.clusterserviceversion.yaml
    yq e -i '.metadata.annotations.containerImage = env(IMG_OPERATOR)' ./config/manifests/bases/ptp-operator.clusterserviceversion.yaml
    yq e -i ".metadata.annotations.[\"operators.openshift.io/must-gather-image\"] = \"${IMG_MUST_GATHER}\"" ./config/manifests/bases/ptp-operator.clusterserviceversion.yaml
    yq e -i '.spec.icon[0].base64data = env(ICON)' ./config/manifests/bases/ptp-operator.clusterserviceversion.yaml
    yq e -i '.spec.icon[0].mediatype = "image/png"' ./config/manifests/bases/ptp-operator.clusterserviceversion.yaml
    yq e -i ".spec.labels.alm-status-descriptors = \"ptp-operator.v${OCP_DATE}\"" ./config/manifests/bases/ptp-operator.clusterserviceversion.yaml
    yq e -i '.spec.template.spec.containers[0].env |= map(select(.name == "LINUXPTP_DAEMON_IMAGE").value = env(IMG_LPTPD))' ./config/manager/env.yaml
    yq e -i '.spec.template.spec.containers[0].env |= map(select(.name == "SIDECAR_EVENT_IMAGE").value = env(IMG_CEP))' ./config/manager/env.yaml
    yq e -i '.spec.template.spec.containers[0].env |= map(select(.name == "KUBE_RBAC_PROXY_IMAGE").value = env(IMG_KUBE_RBAC_PROXY))' ./config/manager/env.yaml

    make bundle VERSION="${OCP_DATE}" BUNDLE_METADATA_OPTS="${BUNDLE_METADATA_OPTS}" IMG="${IMG_OPERATOR}"

    # Build and push the bundle image
    podman build -t "${BUNDLE_IMG}" -f bundle.Dockerfile .
    podman push "${BUNDLE_IMG}"
    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
