#!/bin/bash

# Configuration and variable setup
NAMESPACE="oadp"
MAJOR="1"
MINOR="6"
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
export IMG_VM_FILE_RESTORE="${REGISTRY}/vm-file-restore:${OCP_DATE}"
export IMG_VMFR_ACCESS="${REGISTRY}/vmfr-access:${OCP_DATE}"
export IMG_VMFR_SSHD="${REGISTRY}/vmfr-sshd:${OCP_DATE}"
export IMG_VMFR_FILEBROWSER="${REGISTRY}/vmfr-filebrowser:${OCP_DATE}"
export IMG_CLI_BINARIES="${REGISTRY}/cli-binaries:${OCP_DATE}"
export IMG_VMDP_BINARIES="${REGISTRY}/vmdp-binaries:${OCP_DATE}"
export IMG_KUBEVIRT_DATAMOVER_CONTROLLER="${REGISTRY}/kubevirt-datamover-controller:${OCP_DATE}"
export IMG_KUBEVIRT_DATAMOVER_PLUGIN="${REGISTRY}/kubevirt-datamover-plugin:${OCP_DATE}"
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
    submodule_initialize kubevirt-plugin oadp-${OCP_SHORT}
    submodule_initialize must-gather oadp-${OCP_SHORT}
    submodule_initialize kopia oadp-${OCP_SHORT}
    submodule_initialize restic oadp-${OCP_SHORT}
    submodule_initialize vm-file-restore oadp-${OCP_SHORT}
    submodule_initialize filebrowser oadp-${OCP_SHORT}
    submodule_initialize oadp-cli oadp-${OCP_SHORT}
    submodule_initialize oadp-vmdp oadp-${OCP_SHORT}
    submodule_initialize kubevirt-datamover-controller oadp-${OCP_SHORT}
    submodule_initialize kubevirt-datamover-plugin oadp-${OCP_SHORT}
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
    submodule_reset kubevirt-plugin oadp-${OCP_SHORT}
    submodule_reset must-gather oadp-${OCP_SHORT}
    submodule_reset kopia oadp-${OCP_SHORT}
    submodule_reset restic oadp-${OCP_SHORT}
    submodule_reset vm-file-restore oadp-${OCP_SHORT}
    submodule_reset filebrowser oadp-${OCP_SHORT}
    submodule_reset oadp-cli oadp-${OCP_SHORT}
    submodule_reset oadp-vmdp oadp-${OCP_SHORT}
    submodule_reset kubevirt-datamover-controller oadp-${OCP_SHORT}
    submodule_reset kubevirt-datamover-plugin oadp-${OCP_SHORT}
}

update() {
    BRANCH="oadp-${OCP_SHORT}"

    submodule_update velero ${BRANCH} https://github.com/openshift/velero.git
    submodule_update operator ${BRANCH} https://github.com/openshift/oadp-operator.git
    submodule_update non-admin ${BRANCH} https://github.com/migtools/oadp-non-admin.git
    submodule_update microsoft-azure-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-microsoft-azure.git
    submodule_update openshift-plugin ${BRANCH} https://github.com/openshift/openshift-velero-plugin.git
    submodule_update hypershift-plugin ${BRANCH} https://github.com/openshift/hypershift-oadp-plugin.git
    submodule_update aws-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-aws.git
    submodule_update aws-legacy-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-legacy-aws.git
    submodule_update gcp-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-gcp.git
    submodule_update kubevirt-plugin ${BRANCH} https://github.com/migtools/kubevirt-velero-plugin.git
    submodule_update kopia ${BRANCH} https://github.com/migtools/kopia.git
    submodule_update restic ${BRANCH} https://github.com/openshift/restic.git
    submodule_update must-gather ${BRANCH} https://github.com/openshift/oadp-must-gather.git
    submodule_update vm-file-restore ${BRANCH} https://github.com/migtools/oadp-vm-file-restore.git
    submodule_update filebrowser ${BRANCH} https://github.com/migtools/filebrowser.git
    submodule_update oadp-cli ${BRANCH} https://github.com/migtools/oadp-cli.git
    submodule_update oadp-vmdp ${BRANCH} https://github.com/migtools/oadp-vmdp.git
    submodule_update kubevirt-datamover-controller ${BRANCH} https://github.com/migtools/kubevirt-datamover-controller.git
    submodule_update kubevirt-datamover-plugin ${BRANCH} https://github.com/migtools/kubevirt-datamover-plugin.git
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
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_VM_FILE_RESTORE -f vm-file-restore.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_VMFR_ACCESS -f vmfr-access.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_VMFR_SSHD -f vmfr-sshd.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_VMFR_FILEBROWSER -f vmfr-filebrowser.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_CLI_BINARIES -f cli-binaries.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_VMDP_BINARIES -f vmdp-binaries.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_KUBEVIRT_DATAMOVER_CONTROLLER -f kubevirt-datamover-controller.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_KUBEVIRT_DATAMOVER_PLUGIN -f kubevirt-datamover-plugin.Containerfile .
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
     .env |= map(select(.name == \"RELATED_IMAGE_MUSTGATHER\").value = \"${IMG_MUST_GATHER}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VM_FILE_RESTORE_CONTROLLER\").value = \"${IMG_VM_FILE_RESTORE}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VM_FILE_RESTORE_ACCESS\").value = \"${IMG_VMFR_ACCESS}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VM_FILE_RESTORE_SSH\").value = \"${IMG_VMFR_SSHD}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VM_FILE_RESTORE_BROWSER\").value = \"${IMG_VMFR_FILEBROWSER}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_CONSOLE_CLI_DOWNLOAD\").value = \"${IMG_CLI_BINARIES}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_VMDP_CLI_DOWNLOAD\").value = \"${IMG_VMDP_BINARIES}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_KUBEVIRT_DATAMOVER_CONTROLLER\").value = \"${IMG_KUBEVIRT_DATAMOVER_CONTROLLER}\") |
     .env |= map(select(.name == \"RELATED_IMAGE_KUBEVIRT_DATAMOVER_PLUGIN\").value = \"${IMG_KUBEVIRT_DATAMOVER_PLUGIN}\")
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
