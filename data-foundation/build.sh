#!/bin/bash

NAMESPACE="data-foundation"

source ../common.sh

CEPH_RELEASE="8.1"
export CEPH_VERSION="$CEPH_RELEASE.0-${DATE}"

export IMG_OAUTH_PROXY="$(get_payload_component oauth-proxy)"
export IMG_KUBE_RBAC_PROXY="$(get_payload_component kube-rbac-proxy)"
export IMG_CSI_NODE_DRIVER_REGISTRAR="$(get_payload_component csi-node-driver-registrar)"
export IMG_CSI_RESIZER="$(get_payload_component csi-external-resizer)"
export IMG_CSI_PROVISIONER="$(get_payload_component csi-external-provisioner)"
export IMG_CSI_SNAPSHOTTER="$(get_payload_component csi-external-snapshotter)"
export IMG_CSI_SNAPSHOT_METADATA="$(get_payload_component csi-external-snapshot-metadata)"
export IMG_CSI_ATTACHER="$(get_payload_component csi-external-attacher)"
export IMG_CLI="$(get_payload_component cli)"
export IMG_PROMETHEUS_OPERATOR="$(get_payload_component prometheus-operator)"
export IMG_PROMETHEUS_CONFIG_RELOADER="$(get_payload_component prometheus-config-reloader)"
export IMG_PROMETHEUS="$(get_payload_component prometheus)"
export IMG_PROMETHEUS_ALERTMANAGER="$(get_payload_component prometheus-alertmanager)"

export IMG_NOOBAA_DB=quay.io/sclorg/postgresql-15-c9s:latest

export IMG_CEPH=${REGISTRY}/ceph:${CEPH_VERSION}
export IMG_CEPH_CSI="${REGISTRY}/ceph-csi:${OCP_DATE}"
export IMG_CEPH_CSI_OPERATOR="${REGISTRY}/ceph-csi-operator:${OCP_DATE}"
export IMG_ODF_CLI="${REGISTRY}/odf-cli:${OCP_DATE}"
export IMG_ODF_CONSOLE="${REGISTRY}/odf-console:${OCP_DATE}"
export IMG_COSI_SIDECAR="${REGISTRY}/cosi-sidecar:${OCP_DATE}"
export IMG_EXTERNAL_SNAPSHOTTER_SIDECAR="${REGISTRY}/external-snapshotter-sidecar:${OCP_DATE}"
export IMG_CSI_ADDONS_OPERATOR="${REGISTRY}/csi-addons-operator:${OCP_DATE}"
export IMG_CSI_ADDONS_SIDECAR="${REGISTRY}/csi-addons-sidecar:${OCP_DATE}"
export IMG_MCG_CORE="${REGISTRY}/mcg-core:${OCP_DATE}"
export IMG_MCG_OPERATOR="${REGISTRY}/mcg-operator:${OCP_DATE}"
export IMG_MULTICLUSTER_CONSOLE="${REGISTRY}/multicluster-console:${OCP_DATE}"
export IMG_MULTICLUSTER_OPERATOR="${REGISTRY}/multicluster-operator:${OCP_DATE}"
export IMG_OCS_CLIENT_CONSOLE="${REGISTRY}/ocs-client-console:${OCP_DATE}"
export IMG_OCS_CLIENT_OPERATOR="${REGISTRY}/ocs-client-operator:${OCP_DATE}"
export IMG_OCS_METRICS_EXPORTER="${REGISTRY}/ocs-metrics-exporter:${OCP_DATE}"
export IMG_OCS_OPERATOR="${REGISTRY}/ocs-operator:${OCP_DATE}"
export IMG_ODR_OPERATOR="${REGISTRY}/odr-operator:${OCP_DATE}"
export IMG_ODF_OPERATOR="${REGISTRY}/odf-operator:${OCP_DATE}"
export IMG_ROOK_OPERATOR="${REGISTRY}/rook-operator:${OCP_DATE}"
export IMG_EXTERNAL_SNAPSHOTTER_OPERATOR="${REGISTRY}/external-snapshotter-operator:${OCP_DATE}"
export IMG_CLOUDNATIVE_PG_OPERATOR="${REGISTRY}/cloudnative-pg-operator:${OCP_DATE}"

IMG_BUNDLE_ROOK_OPERATOR="${REGISTRY}/rook-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_CEPH_CSI_OPERATOR="${REGISTRY}/ceph-csi-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_CSI_ADDONS_OPERATOR="${REGISTRY}/csi-addons-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_MCG_OPERATOR="${REGISTRY}/mcg-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_OCS_CLIENT_OPERATOR="${REGISTRY}/ocs-client-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_ODF_PROMETHEUS_OPERATOR="${REGISTRY}/odf-prometheus-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_OCS_OPERATOR="${REGISTRY}/ocs-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_ODR_RECIPE="${REGISTRY}/odr-recipe-bundle:${OCP_DATE}"
IMG_BUNDLE_EXTERNAL_SNAPSHOTTER_OPERATOR="${REGISTRY}/external-snapshotter-bundle:${OCP_DATE}"
IMG_BUNDLE_ODF_OPERATOR="${REGISTRY}/odf-operator-bundle:${OCP_DATE}"
IMG_BUNDLE_ODF_DEPENDENCIES="${REGISTRY}/odf-dependencies-bundle:${OCP_DATE}"

init() {
    submodule_initialize ceph-container release-${CEPH_RELEASE}
    submodule_initialize ceph-csi release-${OCP_SHORT}
    submodule_initialize ceph-csi-operator release-${OCP_SHORT}
    submodule_initialize cloudnative-pg rhodf-${OCP_SHORT}
    submodule_initialize container-object-storage-interface-provisioner-sidecar master
    submodule_initialize kubernetes-csi-addons release-${OCP_SHORT}
    submodule_initialize must-gather release-${OCP_SHORT}
    submodule_initialize noobaa-core release-${OCP_SHORT}
    submodule_initialize noobaa-operator release-${OCP_SHORT}
    submodule_initialize ocs-client-operator release-${OCP_SHORT}
    submodule_initialize ocs-operator release-${OCP_SHORT}
    submodule_initialize odf-cli release-${OCP_SHORT}
    submodule_initialize odf-console release-${OCP_SHORT}
    submodule_initialize odf-console-compatibility release-${OCP_SHORT}
    submodule_initialize odf-multicluster-orchestrator release-${OCP_SHORT}
    submodule_initialize odf-operator release-${OCP_SHORT}
    submodule_initialize ramen release-${OCP_SHORT}
    submodule_initialize recipe release-${OCP_SHORT}
    submodule_initialize rook release-${OCP_SHORT}
    submodule_initialize external-snapshotter release-${OCP_SHORT}
}

deinit() {
    submodule_reset ceph-container release-${CEPH_RELEASE}
    submodule_reset ceph-csi release-${OCP_SHORT}
    submodule_reset ceph-csi-operator release-${OCP_SHORT}
    submodule_reset cloudnative-pg rhodf-${OCP_SHORT}
    submodule_reset container-object-storage-interface-provisioner-sidecar master
    submodule_reset kubernetes-csi-addons release-${OCP_SHORT}
    submodule_reset must-gather release-${OCP_SHORT}
    submodule_reset noobaa-core release-${OCP_SHORT}
    submodule_reset noobaa-operator release-${OCP_SHORT}
    submodule_reset ocs-client-operator release-${OCP_SHORT}
    submodule_reset ocs-operator release-${OCP_SHORT}
    submodule_reset odf-cli release-${OCP_SHORT}
    submodule_reset odf-console release-${OCP_SHORT}
    submodule_reset odf-console-compatibility release-${OCP_SHORT}
    submodule_reset odf-multicluster-orchestrator release-${OCP_SHORT}
    submodule_reset odf-operator release-${OCP_SHORT}
    submodule_reset ramen release-${OCP_SHORT}
    submodule_reset recipe release-${OCP_SHORT}
    submodule_reset rook release-${OCP_SHORT}
    submodule_reset external-snapshotter release-${OCP_SHORT}
}

update() {
    submodule_update ceph-container release-8.1 https://github.com/ibmstorage/rhceph-container.git
    submodule_update ceph-csi release-${OCP_SHORT} https://github.com/red-hat-storage/ceph-csi.git
    submodule_update ceph-csi-operator release-${OCP_SHORT} https://github.com/red-hat-storage/ceph-csi-operator.git
    submodule_update cloudnative-pg rhodf-${OCP_SHORT} https://github.com/red-hat-storage/cloudnative-pg.git
    submodule_update container-object-storage-interface-provisioner-sidecar master https://github.com/kubernetes-retired/container-object-storage-interface-provisioner-sidecar.git
    submodule_update kubernetes-csi-addons release-${OCP_SHORT} https://github.com/red-hat-storage/kubernetes-csi-addons.git
    submodule_update must-gather release-${OCP_SHORT} https://github.com/red-hat-storage/odf-must-gather.git
    submodule_update noobaa-core release-${OCP_SHORT} https://github.com/red-hat-storage/noobaa-core.git
    submodule_update noobaa-operator release-${OCP_SHORT} https://github.com/red-hat-storage/noobaa-operator.git
    submodule_update ocs-client-operator release-${OCP_SHORT} https://github.com/red-hat-storage/ocs-client-operator.git
    submodule_update ocs-operator release-${OCP_SHORT} https://github.com/red-hat-storage/ocs-operator.git
    submodule_update odf-cli release-${OCP_SHORT} https://github.com/red-hat-storage/odf-cli.git
    submodule_update odf-console release-${OCP_SHORT} https://github.com/red-hat-storage/odf-console.git
    submodule_update odf-console-compatibility release-${OCP_SHORT} https://github.com/red-hat-storage/odf-console.git
    submodule_update odf-multicluster-orchestrator release-${OCP_SHORT} https://github.com/red-hat-storage/odf-multicluster-orchestrator.git
    submodule_update odf-operator release-${OCP_SHORT} https://github.com/red-hat-storage/odf-operator.git
    submodule_update ramen release-${OCP_SHORT} https://github.com/red-hat-storage/ramen.git
    submodule_update recipe release-${OCP_SHORT} https://github.com/red-hat-storage/recipe.git
    submodule_update rook release-${OCP_SHORT} https://github.com/red-hat-storage/rook.git
    submodule_update external-snapshotter release-${OCP_SHORT} https://github.com/red-hat-storage/external-snapshotter.git
}

build_containers() {
    # Replace NooBaa version
    sed -i "s|Version = .*|Version = \"${OCP_DATE}\"|g" noobaa-operator/version/version.go

    podman build -t ${IMG_CEPH} -f Dockerfile ceph-container
    podman build --build-arg CI_VERSION=${OCP_DATE} --build-arg IMG_CLI=${IMG_CLI} -t ${IMG_CLOUDNATIVE_PG_OPERATOR} -f cloudnative-pg-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} --build-arg CEPH_IMG=${IMG_CEPH} -t ${IMG_CEPH_CSI} -f ceph-csi.Containerfile ../
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_CEPH_CSI_OPERATOR} -f ceph-csi-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_ODF_CLI} -f odf-cli.Containerfile ..
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_ODF_CONSOLE} -f odf-console.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_COSI_SIDECAR} -f cosi-sidecar.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_CSI_ADDONS_OPERATOR} -f csi-addons-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_CSI_ADDONS_SIDECAR} -f csi-addons-sidecar.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} --build-arg IMG_CLI=${IMG_CLI} -t ${IMG_MCG_CORE} -f mcg-core.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_MCG_OPERATOR} -f mcg-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_MULTICLUSTER_CONSOLE} -f multicluster-console.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_MULTICLUSTER_OPERATOR} -f multicluster-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_OCS_CLIENT_CONSOLE} -f ocs-client-console.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_OCS_CLIENT_OPERATOR} -f ocs-client-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} --build-arg CEPH_IMG=${IMG_CEPH} -t ${IMG_OCS_METRICS_EXPORTER} -f ocs-metrics-exporter.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_OCS_OPERATOR} -f ocs-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_ODR_OPERATOR} -f odr-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_ODF_OPERATOR} -f odf-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} --build-arg CEPH_IMG=${IMG_CEPH} -t ${IMG_ROOK_OPERATOR} -f rook-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_EXTERNAL_SNAPSHOTTER_OPERATOR} -f external-snapshotter-operator.Containerfile .
    podman build --build-arg CI_VERSION=${OCP_DATE} -t ${IMG_EXTERNAL_SNAPSHOTTER_SIDECAR} -f external-snapshotter-sidecar.Containerfile .
}

push_containers() {
    push_all_images
}

build_bundle() {
    convert_all_images_to_digest
    pushd external-snapshotter || return
    make -f Makefile.Downstream.mk bundle BUNDLE_METADATA_OPTS="${BUNDLE_METADATA_OPTS}" BUNDLE_VERSION=${OCP_DATE} \
     BUNDLE_IMG=${IMG_BUNDLE_EXTERNAL_SNAPSHOTTER_OPERATOR} "SKIP_RANGE=>=${PREV_MINOR}.0 <${OCP_DATE}" \
     IMG=${IMG_EXTERNAL_SNAPSHOTTER_OPERATOR}
    podman build -t ${IMG_BUNDLE_EXTERNAL_SNAPSHOTTER_OPERATOR} -f bundle.Dockerfile .
    podman push ${IMG_BUNDLE_EXTERNAL_SNAPSHOTTER_OPERATOR}
    popd || return

    pushd recipe || return
    make crd-bundle-build VERSION=${OCP_DATE} CHANNELS=alpha DEFAULT_CHANNEL=alpha "SKIP_RANGE=>=${PREV_MINOR}.0 <${OCP_DATE}" BUNDLE_IMG=${IMG_BUNDLE_ODR_RECIPE}
    make crd-bundle-push BUNDLE_IMG=${IMG_BUNDLE_ODR_RECIPE}
    popd || return

    pushd rook || return
    ROOK_CSI_CEPH_IMAGE=${IMG_CEPH_CSI} ROOK_CSI_REGISTRAR_IMAGE=${IMG_CSI_NODE_DRIVER_REGISTRAR} \
     ROOK_CSI_RESIZER_IMAGE=${IMG_CSI_RESIZER} ROOK_CSI_PROVISIONER_IMAGE=${IMG_CSI_PROVISIONER} \
     ROOK_CSI_SNAPSHOTTER_IMAGE=${IMG_CSI_SNAPSHOTTER} ROOK_CSI_ATTACHER_IMAGE=${IMG_CSI_ATTACHER} \
     ROOK_CSIADDONS_IMAGE=${IMG_CSI_ADDONS_SIDECAR} CSV_VERSION=${OCP_DATE} VERSION=${OCP_DATE} \
     BUNDLE_IMAGE=${IMG_BUNDLE_ROOK_OPERATOR} ROOK_IMAGE=${IMG_ROOK_OPERATOR} make gen-csv
    VERSION=${OCP_DATE} BUNDLE_IMAGE=${IMG_BUNDLE_ROOK_OPERATOR} DOCKERCMD=podman make bundle
    podman push ${IMG_BUNDLE_ROOK_OPERATOR}
    popd || return

    pushd ceph-csi-operator || return
    make -f Makefile.Downstream.mk bundle-build CHANNELS=alpha DEFAULT_CHANNEL=alpha VERSION=${OCP_DATE} BUNDLE_VERSION=${OCP_DATE} \
     BUNDLE_IMG=${IMG_BUNDLE_CEPH_CSI_OPERATOR} "SKIP_RANGE=>=${PREV_MINOR}.0 <${OCP_DATE}" IMG=${IMG_CEPH_CSI_OPERATOR} \
     KUBE_RBAC_PROXY_IMG=${IMG_KUBE_RBAC_PROXY} CONTAINER_TOOL=podman "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}"
    make -f Makefile.Downstream.mk bundle-push BUNDLE_IMG=${IMG_BUNDLE_CEPH_CSI_OPERATOR} CONTAINER_TOOL=podman
    popd || return

    pushd kubernetes-csi-addons || return
    sed -i "s|sigs.k8s.io/kubebuilder/v4 v4.1.1 .*|sigs.k8s.io/kubebuilder/v4 v4.1.1 h1:cYSgEfjS5qzTdc1RgPHWZgCrgd1USbz2iO+mFr7BPls=|g" tools/go.sum
    sed -i 's|--package=$(PACKAGE_NAME) $(BUNDLE_VERSION)|--package=$(PACKAGE_NAME) --version $(BUNDLE_VERSION) $(BUNDLE_METADATA_OPTS)|g' Makefile
    make bundle CONTAINER_CMD=podman VERSION=${OCP_DATE} BUNDLE_IMG=${IMG_BUNDLE_CSI_ADDONS_OPERATOR} \
     "SKIP_RANGE=>=${PREV_MINOR}.0 <${OCP_DATE}" CONTROLLER_IMG=${IMG_CSI_ADDONS_OPERATOR} BUNDLE_VERSION=${OCP_DATE} \
     SIDECAR_IMG=${IMG_CSI_ADDONS_SIDECAR} RBAC_PROXY_IMG=${IMG_KUBE_RBAC_PROXY} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}"
    podman build -t ${IMG_BUNDLE_CSI_ADDONS_OPERATOR} -f bundle.Dockerfile .
    podman push ${IMG_BUNDLE_CSI_ADDONS_OPERATOR}
    popd || return

    pushd noobaa-operator || return
    make gen-odf-package IMAGE=${IMG_MCG_OPERATOR} BUNDLE_IMAGE=${IMG_BUNDLE_MCG_OPERATOR} VERSION=${OCP_DATE} obc-crd=owned \
     REPO=github.com/red-hat-storage/nooba-operator csv-name=noobaa-operator.clusterserviceversion.yaml cosi-sidecar-image=${IMG_COSI_SIDECAR} \
     "skip-range=>=${PREV_MINOR}.0 <${OCP_DATE}" operator-image=${IMG_MCG_OPERATOR} db-image=${IMG_NOOBAA_DB} \
     psql-12-image=quay.io/sclorg/postgresql-12-c8s:latest core-image=${IMG_MCG_CORE} cnpg-image=${IMG_CLOUDNATIVE_PG_OPERATOR}
    podman build -t ${IMG_BUNDLE_MCG_OPERATOR} -f build/bundle/Dockerfile .
    podman push ${IMG_BUNDLE_MCG_OPERATOR}
    popd || return

    pushd ocs-client-operator || return
    yq -i '.dependencies[2].value.version = ">='${OCP_DATE}'"' config/metadata/dependencies.yaml
    make bundle IMAGE_BUILD_CMD=podman BUNDLE_IMG=${IMG_BUNDLE_OCS_CLIENT_OPERATOR} VERSION=${OCP_DATE} \
     "SKIP_RANGE=>=${PREV_MINOR}.0 <${OCP_DATE}" IMG=${IMG_OCS_CLIENT_OPERATOR} BUNDLE_VERSION=${OCP_DATE} \
     CLUSTER_ENV=openshift OSE_KUBE_RBAC_PROXY_IMG=${IMG_KUBE_RBAC_PROXY} CEPH_CSI_PACKAGE_VERSION=${OCP_DATE} \
     OCS_CLIENT_CONSOLE_IMG=${IMG_OCS_CLIENT_CONSOLE} CSI_ADDONS_BUNDLE_IMG=${IMG_BUNDLE_CSI_ADDONS_OPERATOR} \
     CSI_ADDONS_PACKAGE_VERSION=${OCP_DATE} CSI_IMG_PROVISIONER=${IMG_CSI_PROVISIONER} CSI_IMG_ATTACHER=${IMG_CSI_ATTACHER} \
     CSI_IMG_RESIZER=${IMG_CSI_RESIZER} CSI_IMG_SNAPSHOTTER=${IMG_CSI_SNAPSHOTTER} CSI_IMG_SNAPSHOT_METADATA=${IMG_CSI_SNAPSHOT_METADATA} \
     CSI_IMG_ODF_SNAPSHOTTER=${IMG_EXTERNAL_SNAPSHOTTER_SIDECAR} \
     CSI_IMG_REGISTRAR=${IMG_CSI_NODE_DRIVER_REGISTRAR} CSI_IMG_ADDONS=${IMG_CSI_ADDONS_SIDECAR} \
     CSI_IMG_CEPH_CSI=${IMG_CEPH_CSI} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" CSI_OCP_VERSIONS="v${OCP_SHORT}" \
     SNAPSHOT_CONTROLLER_BUNDLE_IMG=${IMG_BUNDLE_EXTERNAL_SNAPSHOTTER_OPERATOR} SNAPSHOT_CONTROLLER_PACKAGE_VERSION=${OCP_DATE}
    podman build -t ${IMG_BUNDLE_OCS_CLIENT_OPERATOR} -f bundle.Dockerfile .
    podman push ${IMG_BUNDLE_OCS_CLIENT_OPERATOR}
    popd || return

    pushd prometheus-bundle || return
    export VERSION=${OCP_DATE}
    cat config/manager/manager.template.yaml | envsubst > config/manager/manager.yaml
    cat config/manifests/bases/odf-prometheus-operator.clusterserviceversion.template.yaml | \
     envsubst > config/manifests/bases/odf-prometheus-operator.clusterserviceversion.yaml
    pushd config/manager || return
    kustomize edit set image controller=${IMG_PROMETHEUS_OPERATOR}
    popd || return

    kustomize build config/manifests | operator-sdk generate bundle --package="odf-prometheus-operator" \
     --version=${OCP_DATE} --overwrite --extra-service-accounts=prometheus-k8s \
     ${BUNDLE_METADATA_OPTS}
    podman build -t ${IMG_BUNDLE_ODF_PROMETHEUS_OPERATOR} -f bundle.Dockerfile .
    podman push ${IMG_BUNDLE_ODF_PROMETHEUS_OPERATOR}
    popd || return

    pushd ocs-operator || return
    IMAGE_REGISTRY=quay.io/okderators UX_BACKEND_OAUTH_IMAGE=${IMG_OAUTH_PROXY} \
     OCS_IMAGE=${IMG_OCS_OPERATOR} METRICS_EXPORTER_FULL_IMAGE_NAME=${IMG_OCS_METRICS_EXPORTER} \
     OCS_METRICS_EXPORTER_IMAGE=${IMG_OCS_METRICS_EXPORTER} \
     NOOBAA_CORE_IMAGE=${IMG_MCG_CORE} NOOBAA_DB_IMAGE=${IMG_NOOBAA_DB} ROOK_IMAGE=${IMG_ROOK_OPERATOR} \
     CEPH_IMAGE=${IMG_CEPH} KUBE_RBAC_PROXY_IMAGE=${IMG_KUBE_RBAC_PROXY} CSV_VERSION=${OCP_DATE} \
     SKIP_RANGE=">=${PREV_MINOR}.0 <${OCP_DATE}" make gen-release-csv VERSION=${OCP_DATE}

    podman build -t ${IMG_BUNDLE_OCS_OPERATOR} -f Dockerfile.bundle .
    podman push ${IMG_BUNDLE_OCS_OPERATOR}
    popd || return

    pushd odf-operator || return
    make bundle SKIP_RANGE=">=${PREV_MINOR}.0 <${OCP_DATE}" VERSION=${OCP_DATE} BUNDLE_IMG=${IMG_BUNDLE_ODF_OPERATOR} \
      VERSION=${OCP_DATE} IMG=${IMG_ODF_OPERATOR} RBAC_PROXY_IMG=${IMG_KUBE_RBAC_PROXY} ODF_CONSOLE_IMG=${IMG_ODF_CONSOLE} \
      NOOBAA_BUNDLE_NAME=noobaa-operator NOOBAA_BUNDLE_VERSION=v${OCP_DATE} NOOBAA_BUNDLE_IMG=${IMG_BUNDLE_MCG_OPERATOR} \
      OCS_BUNDLE_VERSION=v${OCP_DATE} OCS_BUNDLE_IMG=${IMG_BUNDLE_OCS_OPERATOR} OCS_CLIENT_BUNDLE_VERSION=v${OCP_DATE} \
      OCS_CLIENT_BUNDLE_IMG=${IMG_BUNDLE_OCS_CLIENT_OPERATOR} CSIADDONS_BUNDLE_VERSION=v${OCP_DATE} \
      ODF_SNAPSHOT_CONTROLLER_BUNDLE_IMG=${IMG_BUNDLE_EXTERNAL_SNAPSHOTTER_OPERATOR} ODF_SNAPSHOT_CONTROLLER_BUNDLE_VERSION=v${OCP_DATE} \
      CSIADDONS_BUNDLE_IMG=${IMG_BUNDLE_CSI_ADDONS_OPERATOR} CEPHCSI_BUNDLE_VERSION=v${OCP_DATE} \
      CEPHCSI_BUNDLE_IMG=${IMG_BUNDLE_CEPH_CSI_OPERATOR} ROOK_BUNDLE_VERSION=v${OCP_DATE} ROOK_BUNDLE_IMG=${IMG_BUNDLE_ROOK_OPERATOR} \
      PROMETHEUS_BUNDLE_VERSION=v${OCP_DATE} PROMETHEUS_BUNDLE_IMG=${IMG_BUNDLE_ODF_PROMETHEUS_OPERATOR} \
      RECIPE_BUNDLE_VERSION=v${OCP_DATE} RECIPE_BUNDLE_IMG=${IMG_BUNDLE_ODR_RECIPE} OPERATOR_CATALOGSOURCE=okderators \
      DEFAULT_CHANNEL=alpha PROMETHEUS_SUBSCRIPTION_CHANNEL=alpha
    podman build -t ${IMG_BUNDLE_ODF_OPERATOR} -f bundle.Dockerfile .
    podman build -t ${IMG_BUNDLE_ODF_DEPENDENCIES} -f bundle.odf.deps.Dockerfile .
    podman push ${IMG_BUNDLE_ODF_OPERATOR}
    podman push ${IMG_BUNDLE_ODF_DEPENDENCIES}
    popd || return

    set +x

    echo "./hack/add-bundle.sh ${IMG_BUNDLE_ODF_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_ODF_DEPENDENCIES}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_ROOK_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_CEPH_CSI_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_CSI_ADDONS_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_MCG_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_OCS_CLIENT_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_OCS_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_ODR_RECIPE}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_ODF_PROMETHEUS_OPERATOR}"
    echo "./hack/add-bundle.sh ${IMG_BUNDLE_EXTERNAL_SNAPSHOTTER_OPERATOR}"
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
