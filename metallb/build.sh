#!/bin/bash

# Configuration and variable setup
NAMESPACE="metallb"

source ../common.sh

# Image definitions
IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_METALLB="${REGISTRY}/metallb:${OCP_DATE}"
IMG_FRR="${REGISTRY}/frr:${OCP_DATE}"

IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

## Functions

init() {
    submodule_initialize frr release-${OCP_SHORT}
    submodule_initialize metallb release-${OCP_SHORT}
    submodule_initialize operator release-${OCP_SHORT}

    # Non-standard modification to enable incoming BGPD connections
    if [ "${ACCEPT_INCOMING_BGP_CONNECTIONS:-false}" = "true" ]; then
      echo "ACCEPT_INCOMING_BGP_CONNECTIONS is set to true, enabling FRR"
      yq -i ".frrk8s.frr.acceptIncomingBGPConnections = true" operator/bindata/deployment/helm/frr-k8s/values.yaml
    fi
}

deinit() {
    submodule_reset frr release-${OCP_SHORT}
    submodule_reset metallb release-${OCP_SHORT}
    submodule_reset operator release-${OCP_SHORT}
}

update() {
    submodule_update frr release-${OCP_SHORT} https://github.com/openshift/frr.git
    submodule_update metallb release-${OCP_SHORT} https://github.com/openshift/metallb.git
    submodule_update operator release-${OCP_SHORT} https://github.com/openshift/metallb-operator.git
}

build_containers() {
    podman build -t "${IMG_OPERATOR}" -f operator.Containerfile ./operator
    podman build -t "${IMG_METALLB}" -f metallb.Containerfile ../
    podman build -t "${IMG_FRR}" -f frr.Containerfile ../
}

push_containers() {
    podman push "${IMG_OPERATOR}"
    podman push "${IMG_METALLB}"
    podman push "${IMG_FRR}"
}

build_bundle() {
    pushd operator

    yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\"" manifests/ocpcsv/bases/metallb-operator.clusterserviceversion.yaml
    yq e -i ".spec.template.spec.containers[0].image = \"${IMG_METALLB}\"" manifests/ocpcsv/controller-webhook-patch.yaml
    yq e -i "with(.spec.template.spec.containers[0] ;
      .env |= map(select(.name == \"SPEAKER_IMAGE\").value = \"${IMG_METALLB}\") |
      .env |= map(select(.name == \"CONTROLLER_IMAGE\").value = \"${IMG_METALLB}\") |
      .env |= map(select(.name == \"FRR_IMAGE\").value = \"${IMG_FRR}\") |
      .env |= map(select(.name == \"KUBE_RBAC_PROXY_IMAGE\").value = \"${IMG_KUBE_RBAC_PROXY}\") |
      .env |= map(select(.name == \"FRRK8S_IMAGE\").value = \"${IMG_FRR}\") |
      .image = \"${IMG_OPERATOR}\"
    )" manifests/ocpcsv/ocpvariables.yaml

    # we need to save and restore as operatorsdk works with the local bundle.Dockerfile
    mv bundle.Dockerfile bundle.Dockerfile_orig
    rm -rf _cache/ocpmanifests

    export OPERATOR_SDK=_cache/operator-sdk
    make operator-sdk
    export KUSTOMIZE=_cache/kustomize
    make kustomize
    make manifests

    $OPERATOR_SDK generate kustomize manifests --interactive=false -q
    $KUSTOMIZE build manifests/ocpcsv | $OPERATOR_SDK generate bundle --output-dir _cache/ocpmanifests -q --overwrite --version $OCP_DATE --extra-service-accounts "controller,speaker"
    $OPERATOR_SDK bundle validate _cache/ocpmanifests/

    sed -i 's/LABEL com.redhat.openshift.versions=.*$/LABEL com.redhat.openshift.versions="v'"$OCP_SHORT"'"/g' bundle.Dockerfile

    podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
    podman push "${IMG_BUNDLE}"
    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
