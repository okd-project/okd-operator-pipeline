#!/bin/bash

NAMESPACE="cluster-logging"
export MAJOR=6
export MINOR=3

source ../common.sh

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_LOG_FILE_METRIC_EXPORTER="${REGISTRY}/log-file-metric-exporter:${OCP_DATE}"
IMG_LOKI="${REGISTRY}/loki:${OCP_DATE}"
IMG_LOKI_OPERATOR="${REGISTRY}/loki-operator:${OCP_DATE}"
IMG_LOKISTACK_GATEWAY="${REGISTRY}/lokistack-gateway:${OCP_DATE}"
IMG_VECTOR="${REGISTRY}/vector:${OCP_DATE}"
IMG_OPA_OPENSHIFT="${REGISTRY}/opa-openshift:${OCP_DATE}"
IMG_EVENT_ROUTER="${REGISTRY}/eventrouter:latest"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"
IMG_BUNDLE_LOKI="${REGISTRY}/loki-operator-bundle:${OCP_DATE}"

init() {
    submodule_initialize loki release-${OCP_SHORT}
    submodule_initialize operator release-${OCP_SHORT}
}

deinit() {
    submodule_reset loki release-${OCP_SHORT}
    submodule_reset operator release-${OCP_SHORT}
}

build_containers() {
    # Build all container images
    podman build -t $IMG_OPERATOR -f operator.Containerfile ../
    podman build -t $IMG_LOG_FILE_METRIC_EXPORTER -f log-file-metric-exporter.Containerfile .
    podman build -t $IMG_LOKI -f loki.Containerfile --build-arg=VERSION=${OCP_DATE} .
    podman build -t $IMG_LOKI_OPERATOR -f loki-operator.Containerfile .
    podman build -t $IMG_LOKISTACK_GATEWAY -f lokistack-gateway.Containerfile .
    podman build -t $IMG_VECTOR -f vector.Containerfile .
    podman build -t $IMG_OPA_OPENSHIFT -f opa-openshift.Containerfile .
    podman build -t $IMG_EVENT_ROUTER -f eventrouter.Containerfile .
}

push_containers() {
    podman push $IMG_OPERATOR
    podman push $IMG_LOG_FILE_METRIC_EXPORTER
    podman push $IMG_LOKI
    podman push $IMG_LOKI_OPERATOR
    podman push $IMG_LOKISTACK_GATEWAY
    podman push $IMG_VECTOR
    podman push $IMG_OPA_OPENSHIFT
    podman push $IMG_EVENT_ROUTER
}

build_bundle() {
    pushd loki/operator

    export OPERATOR_IMG=$IMG_LOKI_OPERATOR
    export LOKI_IMAGE=$IMG_LOKI
    export VECTOR_IMAGE=$IMG_VECTOR
    export LOG_FILE_METRIC_EXPORTER_IMAGE=$IMG_LOG_FILE_METRIC_EXPORTER
    export LOKISTACK_GATEWAY_IMAGE=$IMG_LOKISTACK_GATEWAY
    export OPA_OPENSHIFT_IMAGE=$IMG_OPA_OPENSHIFT
    export KUBE_RBAC_PROXY_IMAGE=$(get_payload_component kube-rbac-proxy)

    yq e -i ".metadata.annotations.containerImage = env(OPERATOR_IMG)" ./config/manifests/openshift/bases/loki-operator.clusterserviceversion.yaml
    yq e -i "with(.spec.template.spec.containers[0] ;
      .image = env(OPERATOR_IMG) |
      .env |= map(select(.name == \"RELATED_IMAGE_LOKI\").value = env(LOKI_IMAGE)) |
      .env |= map(select(.name == \"VECTOR_IMAGE\").value = env(VECTOR_IMAGE)) |
      .env |= map(select(.name == \"LOG_FILE_METRIC_EXPORTER_IMAGE\").value = env(LOG_FILE_METRIC_EXPORTER_IMAGE)) |
      .env |= map(select(.name == \"RELATED_IMAGE_GATEWAY\").value = env(LOKISTACK_GATEWAY_IMAGE)) |
      .env |= map(select(.name == \"RELATED_IMAGE_OPA\").value = env(OPA_OPENSHIFT_IMAGE))
    )" ./config/overlays/openshift/manager_related_image_patch.yaml
    yq e -i "with(.spec.template.spec ;
      .containers[] | select(.name == \"kube-rbac-proxy\").image = env(KUBE_RBAC_PROXY_IMAGE)
    )" ./config/overlays/openshift/manager_auth_proxy_patch.yaml

    make bundle VARIANT=openshift VERSION=${OCP_DATE} IMG=${IMG_LOKI} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
     BUNDLE_IMG=${IMG_BUNDLE_LOKI}

    pushd bundle/openshift
    podman build -t $IMG_BUNDLE_LOKI -f bundle.Dockerfile .
    podman push $IMG_BUNDLE_LOKI
    popd

    popd

    pushd operator

    export IMG_LOG_FILE_METRIC_EXPORTER=${IMG_LOG_FILE_METRIC_EXPORTER}
    export IMG_VECTOR=${IMG_VECTOR}
    export IMG_OPERATOR=${IMG_OPERATOR}

    yq e -i ".metadata.annotations.containerImage = env(IMG_OPERATOR)" ./config/manifests/bases/cluster-logging.clusterserviceversion.yaml
    yq -e -i "with(.spec.template.spec.containers[0] ;
      .env |= map(select(.name == \"RELATED_IMAGE_LOG_FILE_METRIC_EXPORTER\").value = env(IMG_LOG_FILE_METRIC_EXPORTER)) |
      .env |= map(select(.name == \"RELATED_IMAGE_VECTOR\").value = env(IMG_VECTOR))
    )" ./config/manager/manager.yaml

    pushd config/manager
    kustomize edit set image controller=${IMG_OPERATOR}
    popd

    kustomize build config/manifests | operator-sdk generate bundle -q --overwrite --version ${OCP_DATE} ${BUNDLE_METADATA_OPTS}
    operator-sdk bundle validate --verbose ./bundle

    podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
    podman push $IMG_BUNDLE

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
