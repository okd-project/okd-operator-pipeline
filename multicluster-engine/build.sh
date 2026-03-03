#!/bin/bash

# Configuration and variable setup
NAMESPACE="multicluster-engine"
MAJOR=2
MINOR=10

source ../common.sh

# Image definitions
export IMG_ASSISTED_IMAGE_SERVICE="${REGISTRY}/assisted-image-service:${OCP_DATE}"
export IMG_ASSISTED_INSTALLER="${REGISTRY}/assisted-installer:${OCP_DATE}"
export IMG_ASSISTED_INSTALLER_AGENT="${REGISTRY}/assisted-installer-agent:${OCP_DATE}"
export IMG_ASSISTED_INSTALLER_CONTROLLER="${REGISTRY}/assisted-installer-controller:${OCP_DATE}"
export IMG_ASSISTED_SERVICE_9="${REGISTRY}/assisted-service-9:${OCP_DATE}"
export IMG_BACKPLANE_OPERATOR="${REGISTRY}/backplane-operator:${OCP_DATE}"
export IMG_ADDON_MANAGER="${REGISTRY}/addon-manager:${OCP_DATE}"
export IMG_CLUSTER_API_PROVIDER_AGENT="${REGISTRY}/cluster-api-provider-agent:${OCP_DATE}"
export IMG_CLUSTER_API_PROVIDER_KUBEVIRT="${REGISTRY}/cluster-api-provider-kubevirt:${OCP_DATE}"
export IMG_CLUSTER_CURATOR_CONTROLLER="${REGISTRY}/cluster-curator-controller:${OCP_DATE}"
export IMG_CLUSTER_IMAGE_SET_CONTROLLER="${REGISTRY}/cluster-image-set-controller:${OCP_DATE}"
export IMG_CLUSTER_PROXY="${REGISTRY}/cluster-proxy:${OCP_DATE}"
export IMG_CLUSTER_PROXY_ADDON="${REGISTRY}/cluster-proxy-addon:${OCP_DATE}"
export IMG_CLUSTERCLAIMS_CONTROLLER="${REGISTRY}/clusterclaims-controller:${OCP_DATE}"
export IMG_CLUSTERLIFECYCLE_STATE_METRICS="${REGISTRY}/clusterlifecycle-state-metrics:${OCP_DATE}"
export IMG_CONSOLE="${REGISTRY}/console:${OCP_DATE}"
export IMG_DISCOVERY="${REGISTRY}/discovery:${OCP_DATE}"
export IMG_HIVE="${REGISTRY}/hive:${OCP_DATE}"
export IMG_HYPERSHIFT_ADDON_OPERATOR="${REGISTRY}/hypershift-addon-operator:${OCP_DATE}"
export IMG_HYPERSHIFT_CLI="${REGISTRY}/hypershift-cli:${OCP_DATE}"
export IMG_HYPERSHIFT_OPERATOR="${REGISTRY}/hypershift-operator:${OCP_DATE}"
export IMG_IMAGE_BASED_INSTALL_OPERATOR="${REGISTRY}/image-based-install-operator:${OCP_DATE}"
export IMG_MANAGED_SERVICEACCOUNT="${REGISTRY}/managed-serviceaccount:${OCP_DATE}"
export IMG_MANAGEDCLUSTER_IMPORT_CONTROLLER="${REGISTRY}/managedcluster-import-controller:${OCP_DATE}"
export IMG_MULTICLOUD_MANAGER="${REGISTRY}/multicloud-manager:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
export IMG_PLACEMENT="${REGISTRY}/placement:${OCP_DATE}"
export IMG_PROVIDER_CREDENTIAL_CONTROLLER="${REGISTRY}/provider-credential-controller:${OCP_DATE}"
export IMG_REGISTRATION="${REGISTRY}/registration:${OCP_DATE}"
export IMG_REGISTRATION_OPERATOR="${REGISTRY}/registration-operator:${OCP_DATE}"
export IMG_WORK="${REGISTRY}/work:${OCP_DATE}"
export IMG_CLUSTER_API_WEBHOOK_CONFIG="${REGISTRY}/cluster-api-webhook-config:${OCP_DATE}"
export IMG_CLUSTER_API_PROVIDER_OPENSHIFT_ASSISTED_BOOTSTRAP="${REGISTRY}/cluster-api-provider-openshift-assisted-bootstrap:${OCP_DATE}"
export IMG_CLUSTER_API_PROVIDER_OPENSHIFT_ASSISTED_CONTROL_PLANE="${REGISTRY}/cluster-api-provider-openshift-assisted-control-plane:${OCP_DATE}"
export IMG_POSTGRESQL_12="quay.io/sclorg/postgresql-12-c8s:latest"
export IMG_KUBE_RBAC_PROXY="$(get_payload_component kube-rbac-proxy)"
export IMG_CLUSTER_API="$(get_payload_component cluster-capi-controllers)"
export IMG_AWS_CLUSTER_API_CONTROLLERS="$(get_payload_component aws-cluster-api-controllers)"
export IMG_CLI="$(get_payload_component cli-artifacts)"
export IMG_BAREMETAL_CLUSTER_API_CONTROLLERS="$(get_payload_component baremetal-cluster-api-controllers)"

IMG_BUNDLE="${REGISTRY}/multicluster-engine-bundle:${OCP_DATE}"

## Functions

init() {
    submodule_initialize assisted-image-service release-ocm-2.15
    submodule_initialize assisted-installer release-ocm-2.15
    submodule_initialize assisted-installer-agent release-ocm-2.15
    submodule_initialize assisted-service release-ocm-2.15
    submodule_initialize backplane-must-gather backplane-2.10
    submodule_initialize backplane-operator backplane-2.10
    submodule_initialize cluster-api-installer backplane-2.10
    submodule_initialize cluster-api-provider-agent release-ocm-2.15
    submodule_initialize cluster-api-provider-kubevirt release-4.21
    submodule_initialize cluster-api-provider-openshift-assisted backplane-2.10
    submodule_initialize cluster-curator-controller backplane-2.10
    submodule_initialize cluster-image-set-controller backplane-2.10
    submodule_initialize cluster-proxy backplane-2.10
    submodule_initialize cluster-proxy-addon backplane-2.10
    submodule_initialize clusterclaims-controller backplane-2.10
    submodule_initialize clusterlifecycle-state-metrics backplane-2.10
    submodule_initialize console backplane-2.10
    submodule_initialize discovery backplane-2.10
    submodule_initialize hive master
    submodule_initialize hypershift release-4.21
    submodule_initialize hypershift-addon-operator backplane-2.10
    submodule_initialize image-based-install-operator backplane-2.10
    submodule_initialize managed-serviceaccount backplane-2.10
    submodule_initialize managedcluster-import-controller backplane-2.10
    submodule_initialize multicloud-operators-foundation backplane-2.10
    submodule_initialize ocm backplane-2.10
    submodule_initialize provider-credential-controller backplane-2.10
}

deinit() {
    submodule_reset assisted-image-service release-ocm-2.15
    submodule_reset assisted-installer release-ocm-2.15
    submodule_reset assisted-installer-agent release-ocm-2.15
    submodule_reset assisted-service release-ocm-2.15
    submodule_reset backplane-must-gather backplane-2.10
    submodule_reset backplane-operator backplane-2.10
    submodule_reset cluster-api-installer backplane-2.10
    submodule_reset cluster-api-provider-agent release-ocm-2.15
    submodule_reset cluster-api-provider-kubevirt release-4.21
    submodule_reset cluster-api-provider-openshift-assisted backplane-2.10
    submodule_reset cluster-curator-controller backplane-2.10
    submodule_reset cluster-image-set-controller backplane-2.10
    submodule_reset cluster-proxy backplane-2.10
    submodule_reset cluster-proxy-addon backplane-2.10
    submodule_reset clusterclaims-controller backplane-2.10
    submodule_reset clusterlifecycle-state-metrics backplane-2.10
    submodule_reset console backplane-2.10
    submodule_reset discovery backplane-2.10
    submodule_reset hive master
    submodule_reset hypershift release-4.21
    submodule_reset hypershift-addon-operator backplane-2.10
    submodule_reset image-based-install-operator backplane-2.10
    submodule_reset managed-serviceaccount backplane-2.10
    submodule_reset managedcluster-import-controller backplane-2.10
    submodule_reset multicloud-operators-foundation backplane-2.10
    submodule_reset ocm backplane-2.10
    submodule_reset provider-credential-controller backplane-2.10
}

update() {
    submodule_update assisted-image-service release-ocm-2.15 https://github.com/openshift/assisted-image-service.git
    submodule_update assisted-installer release-ocm-2.15 https://github.com/openshift/assisted-installer
    submodule_update assisted-installer-agent release-ocm-2.15 https://github.com/openshift/assisted-installer-agent
    submodule_update assisted-service release-ocm-2.15 https://github.com/openshift/assisted-service.git
    submodule_update backplane-must-gather backplane-2.10 https://github.com/stolostron/backplane-must-gather.git
    submodule_update backplane-operator backplane-2.10 https://github.com/stolostron/backplane-operator
    submodule_update cluster-api-installer backplane-2.10 https://github.com/stolostron/cluster-api-installer.git
    submodule_update cluster-api-provider-agent release-ocm-2.15 https://github.com/openshift/cluster-api-provider-agent
    submodule_update cluster-api-provider-kubevirt release-4.21 https://github.com/openshift/cluster-api-provider-kubevirt.git
    submodule_update cluster-api-provider-openshift-assisted backplane-2.10 https://github.com/openshift-assisted/cluster-api-provider-openshift-assisted.git
    submodule_update cluster-curator-controller backplane-2.10 https://github.com/stolostron/cluster-curator-controller.git
    submodule_update cluster-image-set-controller backplane-2.10 https://github.com/stolostron/cluster-image-set-controller.git
    submodule_update cluster-proxy backplane-2.10 https://github.com/stolostron/cluster-proxy
    submodule_update cluster-proxy-addon backplane-2.10 https://github.com/stolostron/cluster-proxy-addon.git
    submodule_update clusterclaims-controller backplane-2.10 https://github.com/stolostron/clusterclaims-controller
    submodule_update clusterlifecycle-state-metrics backplane-2.10 https://github.com/stolostron/clusterlifecycle-state-metrics.git
    submodule_update console backplane-2.10 https://github.com/stolostron/console.git
    submodule_update discovery backplane-2.10 https://github.com/stolostron/discovery.git
    submodule_update hive master https://github.com/openshift/hive.git
    submodule_update hypershift release-4.21 https://github.com/openshift/hypershift.git
    submodule_update hypershift-addon-operator backplane-2.10 https://github.com/stolostron/hypershift-addon-operator.git
    submodule_update image-based-install-operator backplane-2.10 https://github.com/openshift/image-based-install-operator.git
    submodule_update managed-serviceaccount backplane-2.10 https://github.com/stolostron/managed-serviceaccount
    submodule_update managedcluster-import-controller backplane-2.10 https://github.com/stolostron/managedcluster-import-controller.git
    submodule_update multicloud-operators-foundation backplane-2.10 https://github.com/stolostron/multicloud-operators-foundation.git
    submodule_update ocm backplane-2.10 https://github.com/stolostron/ocm.git
    submodule_update provider-credential-controller backplane-2.10 https://github.com/stolostron/provider-credential-controller.git
}

build_containers() {
    podman build -t "${IMG_ASSISTED_IMAGE_SERVICE}" -f assisted-image-service.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_ASSISTED_INSTALLER}" -f assisted-installer.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_ASSISTED_INSTALLER_AGENT}" -f assisted-installer-agent.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg IMG_CLI=$IMG_CLI .
    podman build -t "${IMG_ASSISTED_INSTALLER_CONTROLLER}" -f assisted-installer-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg IMG_CLI=$IMG_CLI .
    podman build -t "${IMG_ASSISTED_SERVICE_9}" -f assisted-service-9.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg IMG_CLI=$IMG_CLI .
    podman build -t "${IMG_BACKPLANE_OPERATOR}" -f backplane-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_ADDON_MANAGER}" -f addon-manager.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_API_PROVIDER_AGENT}" -f cluster-api-provider-agent.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_API_PROVIDER_KUBEVIRT}" -f cluster-api-provider-kubevirt.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_CURATOR_CONTROLLER}" -f cluster-curator-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_IMAGE_SET_CONTROLLER}" -f cluster-image-set-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_PROXY}" -f cluster-proxy.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_PROXY_ADDON}" -f cluster-proxy-addon.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTERCLAIMS_CONTROLLER}" -f clusterclaims-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTERLIFECYCLE_STATE_METRICS}" -f clusterlifecycle-state-metrics.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CONSOLE}" -f console.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_DISCOVERY}" -f discovery.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_HIVE}" -f hive.Containerfile --build-arg "CI_VERSION=$OCP_DATE" ../
    podman build -t "${IMG_HYPERSHIFT_ADDON_OPERATOR}" -f hypershift-addon-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_HYPERSHIFT_CLI}" -f hypershift-cli.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_HYPERSHIFT_OPERATOR}" -f hypershift-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_IMAGE_BASED_INSTALL_OPERATOR}" -f image-based-install-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MANAGEDCLUSTER_IMPORT_CONTROLLER}" -f managedcluster-import-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MANAGED_SERVICEACCOUNT}" -f managed-serviceaccount.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MULTICLOUD_MANAGER}" -f multicloud-manager.Containerfile --build-arg "CI_VERSION=$OCP_DATE" ../
    podman build -t "${IMG_MUST_GATHER}" -f must-gather.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_PLACEMENT}" -f placement.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_PROVIDER_CREDENTIAL_CONTROLLER}" -f provider-credential-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_REGISTRATION}" -f registration.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_REGISTRATION_OPERATOR}" -f registration-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_WORK}" -f work.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_API_WEBHOOK_CONFIG}" -f cluster-api-webhook-config.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_API_PROVIDER_OPENSHIFT_ASSISTED_BOOTSTRAP}" -f cluster-api-provider-openshift-assisted-bootstrap.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_API_PROVIDER_OPENSHIFT_ASSISTED_CONTROL_PLANE}" -f cluster-api-provider-openshift-assisted-control-plane.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
}

push_containers() {
    push_all_images
}

build_bundle() {
    convert_all_images_to_digest

    export VERSION=$OCP_DATE
    export ENV_OVERRIDES="$(envsubst < operand-env.yaml)"
    export RELATED_IMAGES="$(envsubst < related-images.yaml)"

    pushd backplane-operator

    yq e -i 'select(.kind == "Deployment").spec.template.spec.containers[0].env += env(ENV_OVERRIDES)' config/manager/manager.yaml

    make bundle "VERSION=$OCP_DATE" "BUNDLE_METADATA_OPTS=$BUNDLE_METADATA_OPTS" BUNDLE_IMG=$IMG_BUNDLE IMG=$IMG_BACKPLANE_OPERATOR

    yq e -i '.spec.relatedImages += env(RELATED_IMAGES)' bundle/manifests/multicluster-engine.clusterserviceversion.yaml

    podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
    podman push "${IMG_BUNDLE}"

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
