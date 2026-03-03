#!/bin/bash

# Configuration and variable setup
NAMESPACE="oadp"
MAJOR="1"
MINOR="5"
KUBEVIRT_PLUGIN_RELEASE="0.8"
source ../common.sh

# Image definitions
export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_VELERO="${REGISTRY}/velero:${OCP_DATE}"
export IMG_AWS_PLUGIN="${REGISTRY}/aws-plugin:${OCP_DATE}"
export IMG_AZURE_PLUGIN="${REGISTRY}/azure-plugin:${OCP_DATE}"
export IMG_GCP_PLUGIN="${REGISTRY}/gcp-plugin:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
export IMG_OPENSHIFT_PLUGIN="${REGISTRY}/openshift-plugin:${OCP_DATE}"
export IMG_NON_ADMIN="${REGISTRY}/non-admin:${OCP_DATE}"
export IMG_HYPERSHIFT_PLUGIN="${REGISTRY}/hypershift-plugin:${OCP_DATE}"
export IMG_AWS_LEGACY_PLUGIN="${REGISTRY}/aws-legacy-plugin:${OCP_DATE}"
export IMG_KUBEVIRT_PLUGIN="${REGISTRY}/kubevirt-plugin:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/bundle:${OCP_DATE}"
IMG_CLI="$(get_payload_component "cli")"

## Functions

init() {
    submodule_initialize operator oadp-${OCP_SHORT}
    submodule_initialize velero oadp-${OCP_SHORT}
    submodule_initialize aws-plugin oadp-${OCP_SHORT}
    submodule_initialize microsoft-azure-plugin oadp-${OCP_SHORT}
    submodule_initialize openshift-plugin oadp-${OCP_SHORT}
    submodule_initialize hypershift-plugin oadp-${OCP_SHORT}
    submodule_initialize non-admin oadp-${OCP_SHORT}
    submodule_initialize gcp-plugin oadp-${OCP_SHORT}
    submodule_initialize aws-legacy-plugin oadp-${OCP_SHORT}
    submodule_initialize kubevirt-plugin release-v0.8
}

deinit() {
    submodule_reset operator oadp-${OCP_SHORT}
    submodule_reset velero oadp-${OCP_SHORT}
    submodule_reset aws-plugin oadp-${OCP_SHORT}
    submodule_reset microsoft-azure-plugin oadp-${OCP_SHORT}
    submodule_reset openshift-plugin oadp-${OCP_SHORT}
    submodule_reset hypershift-plugin oadp-${OCP_SHORT}
    submodule_reset non-admin oadp-${OCP_SHORT}
    submodule_reset gcp-plugin oadp-${OCP_SHORT}
    submodule_reset aws-legacy-plugin oadp-${OCP_SHORT}
    submodule_reset kubevirt-plugin release-v0.8
}

update() {
    BRANCH="oadp-${OCP_SHORT}"
    KUBEVIRT_BRANCH="release-v${KUBEVIRT_PLUGIN_RELEASE}"

    submodule_update velero ${BRANCH} https://github.com/openshift/velero.git
    submodule_update operator ${BRANCH} https://github.com/openshift/oadp-operator.git
    submodule_update non-admin ${BRANCH} https://github.com/migtools/oadp-non-admin.git
    submodule_update microsoft-azure-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-microsoft-azure.git
    submodule_update openshift-plugin ${BRANCH} https://github.com/openshift/openshift-velero-plugin.git
    submodule_update hypershift-plugin ${BRANCH} https://github.com/openshift/hypershift-oadp-plugin.git
    submodule_update aws-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-aws.git
    submodule_update aws-legacy-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-legacy-aws.git
    submodule_update gcp-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-gcp.git
    submodule_update kubevirt-plugin ${KUBEVIRT_BRANCH} https://github.com/migtools/kubevirt-velero-plugin.git
    submodule_update kopia ${BRANCH} https://github.com/migtools/kopia.git
    submodule_update restic ${BRANCH} https://github.com/openshift/restic.git
}

build_containers() {
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_VELERO -f velero.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_OPERATOR -f operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_AWS_PLUGIN -f aws-plugin.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_AZURE_PLUGIN -f microsoft-azure-plugin.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_GCP_PLUGIN -f gcp-plugin.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_OPENSHIFT_PLUGIN -f openshift-plugin.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_NON_ADMIN -f non-admin.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_HYPERSHIFT_PLUGIN -f hypershift-plugin.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_AWS_LEGACY_PLUGIN -f aws-legacy-plugin.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_KUBEVIRT_PLUGIN -f kubevirt-plugin.Containerfile .
    podman build --build-arg VELERO_IMG=$IMG_VELERO -t $IMG_MUST_GATHER --build-arg IMG_CLI=$IMG_CLI -f must-gather.Containerfile .
}

push_containers() {
    push_all_images
}

build_bundle() {
    pushd operator

    yq e -i "with((select(.kind == \"Deployment\") | .spec.template.spec.containers[0]) ;
     .env |= map(select(.name == \"RELATED_IMAGE_VELERO\").value = \"${IMG_VELERO}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VELERO_PLUGIN_FOR_AWS\").value = \"${IMG_AWS_PLUGIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VELERO_PLUGIN_FOR_MICROSOFT_AZURE\").value = \"${IMG_AZURE_PLUGIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VELERO_PLUGIN_FOR_GCP\").value = \"${IMG_GCP_PLUGIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_OPENSHIFT_VELERO_PLUGIN\").value = \"${IMG_OPENSHIFT_PLUGIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_NON_ADMIN_CONTROLLER\").value = \"${IMG_NON_ADMIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_HYPERSHIFT_VELERO_PLUGIN\").value = \"${IMG_HYPERSHIFT_PLUGIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VELERO_PLUGIN_FOR_LEGACY_AWS\").value = \"${IMG_AWS_LEGACY_PLUGIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_KUBEVIRT_VELERO_PLUGIN\").value = \"${IMG_KUBEVIRT_PLUGIN}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_MUSTGATHER\").value = \"${IMG_MUST_GATHER}\")
    )" ./config/manager/manager.yaml

    # Replace CSV icon
    BASE64_ICON=$(base64 -w0 ../../icon.png)
    yq e -i ".spec.icon[0].base64data = \"${BASE64_ICON}\"" ./config/manifests/bases/oadp-operator.clusterserviceversion.yaml
    yq e -i ".metadata.annotations.[\"operators.openshift.io/must-gather-image\"] = \"${IMG_MUST_GATHER}\"" ./config/manifests/bases/oadp-operator.clusterserviceversion.yaml
    yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\"" ./config/manifests/bases/oadp-operator.clusterserviceversion.yaml

    make bundle DEFAULT_VERSION=${OCP_DATE} \
           VERSION=${OCP_DATE} \
           IMG=${IMG_OPERATOR} \
           BUNDLE_METADATA_OPTS="${BUNDLE_METADATA_OPTS}" \
           BUNDLE_IMG=${IMG_BUNDLE}

    podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
    podman push $IMG_BUNDLE

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
