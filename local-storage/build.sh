#!/bin/bash

NAMESPACE="local-storage"

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_DISKMAKER="${REGISTRY}/diskmaker:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
export IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

init() {
    submodule_initialize operator release-${OCP_SHORT}
}

deinit() {
    submodule_reset operator release-${OCP_SHORT}
}

update() {
    submodule_update operator release-${OCP_SHORT} https://github.com/openshift/local-storage-operator.git
}

build_containers() {
    podman build -t $IMG_OPERATOR -f operator.Containerfile .
    podman build -t $IMG_DISKMAKER -f diskmaker.Containerfile .
    podman build -t $IMG_MUST_GATHER -f mustgather.Containerfile .
}

push_containers() {
    push_all_images
    convert_all_images_to_digest
}

build_bundle() {
    pushd operator

    export VERSION=$OCP_DATE
    export ICON="$(base64 -w 0 ../icon.png)"

    # Patch
    yq e -i ".metadata.name = \"local-storage-operator.v${OCP_DATE}\"" ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.version = env(VERSION)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.metadata.annotations.containerImage = env(IMG_OPERATOR)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.metadata.annotations.support = "OKD Community"' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.description = "Operator that configures local storage volumes for use in OKD. OKD 4.2 and above are the only supported OKD versions."' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.icon[0].base64data = env(ICON)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.icon[0].mediatype = "image/png"' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.provider.name = "OKD Community"' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i ".spec.labels.alm-status-descriptors = \"local-storage-operator.v${OCP_DATE}\"" ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].image = env(IMG_OPERATOR)' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].env |= map(select(.name == "KUBE_RBAC_PROXY_IMAGE").value = env(IMG_KUBE_RBAC_PROXY))' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].env |= map(select(.name == "DISKMAKER_IMAGE").value = env(IMG_DISKMAKER))' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml
    yq e -i '.spec.install.spec.deployments[0].spec.template.spec.containers[0].env |= map(select(.name == "MUSTGATHER_IMAGE").value = env(IMG_MUST_GATHER))' ./config/manifests/stable/local-storage-operator.clusterserviceversion.yaml

    pushd config
    podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
    podman push $IMG_BUNDLE
    popd
    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
