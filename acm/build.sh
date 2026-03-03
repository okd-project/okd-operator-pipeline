#!/usr/bin/bash

# Configuration and variable setup
MAJOR=2
MINOR=15

FLIGHTCTL_RELEASE=0.8
SUBMARINER_RELEASE=0.21
VOLSYNC_RELEASE=0.13

NAMESPACE="acm"

source ../common.sh

# Image definitions
export IMG_ACM_CLI="${REGISTRY}/cli:${OCP_DATE}"
export IMG_CLUSTER_BACKUP_OPERATOR="${REGISTRY}/cluster-backup-operator:${OCP_DATE}"
export IMG_CLUSTER_PERMISSION="${REGISTRY}/cluster-permission:${OCP_DATE}"
export IMG_CONFIG_POLICY_CONTROLLER="${REGISTRY}/config-policy-controller:${OCP_DATE}"
export IMG_CONSOLE="${REGISTRY}/console:${OCP_DATE}"
export IMG_ENDPOINT_MONITORING_OPERATOR="${REGISTRY}/endpoint-monitoring-operator:${OCP_DATE}"
export IMG_FLIGHTCTL_API="${REGISTRY}/flightctl-api:${OCP_DATE}"
export IMG_FLIGHTCTL_OCP_UI="${REGISTRY}/flightctl-ocp-ui:${OCP_DATE}"
export IMG_FLIGHTCTL_PERIODIC="${REGISTRY}/flightctl-periodic:${OCP_DATE}"
export IMG_FLIGHTCTL_UI="${REGISTRY}/flightctl-ui:${OCP_DATE}"
export IMG_FLIGHTCTL_WORKER="${REGISTRY}/flightctl-worker:${OCP_DATE}"
export IMG_FLIGHTCTL_CLI_ARTIFACTS="${REGISTRY}/flightctl-cli-artifacts:${OCP_DATE}"
export IMG_GOVERNANCE_POLICY_ADDON_CONTROLLER="${REGISTRY}/governance-policy-addon-controller:${OCP_DATE}"
export IMG_GOVERNANCE_POLICY_FRAMEWORK_ADDON="${REGISTRY}/governance-policy-framework-addon:${OCP_DATE}"
export IMG_GOVERNANCE_POLICY_PROPAGATOR="${REGISTRY}/governance-policy-propagator:${OCP_DATE}"
export IMG_GRAFANA="${REGISTRY}/grafana:${OCP_DATE}"
export IMG_GRAFANA_DASHBOARD_LOADER="${REGISTRY}/grafana-dashboard-loader:${OCP_DATE}"
export IMG_INSIGHTS_CLIENT="${REGISTRY}/insights-client:${OCP_DATE}"
export IMG_INSIGHTS_METRICS="${REGISTRY}/insights-metrics:${OCP_DATE}"
export IMG_KLUSTERLET_ADDON_CONTROLLER="${REGISTRY}/klusterlet-addon-controller:${OCP_DATE}"
export IMG_KUBE_STATE_METRICS="${REGISTRY}/kube-state-metrics:${OCP_DATE}"
export IMG_LIGHTHOUSE_AGENT="${REGISTRY}/lighthouse-agent:${OCP_DATE}"
export IMG_LIGHTHOUSE_COREDNS="${REGISTRY}/lighthouse-coredns:${OCP_DATE}"
export IMG_MEMCACHED_EXPORTER="${REGISTRY}/memcached-exporter:${OCP_DATE}"
export IMG_METRICS_COLLECTOR="${REGISTRY}/metrics-collector:${OCP_DATE}"
export IMG_MULTICLOUD_INTEGRATIONS="${REGISTRY}/multicloud-integrations:${OCP_DATE}"
export IMG_MULTICLUSTER_OBSERVABILITY_ADDON="${REGISTRY}/multicluster-observability-addon:${OCP_DATE}"
export IMG_MULTICLUSTER_OBSERVABILITY_OPERATOR="${REGISTRY}/multicluster-observability-operator:${OCP_DATE}"
export IMG_MULTICLUSTER_OPERATORS_APPLICATION="${REGISTRY}/multicluster-operators-application:${OCP_DATE}"
export IMG_MULTICLUSTER_OPERATORS_CHANNEL="${REGISTRY}/multicluster-operators-channel:${OCP_DATE}"
export IMG_MULTICLUSTER_OPERATORS_SUBSCRIPTION="${REGISTRY}/multicluster-operators-subscription:${OCP_DATE}"
export IMG_MULTICLUSTERHUB_OPERATOR="${REGISTRY}/multiclusterhub-operator:${OCP_DATE}"
export IMG_NETTEST="${REGISTRY}/nettest:${OCP_DATE}"
export IMG_NODE_EXPORTER="${REGISTRY}/node-exporter:${OCP_DATE}"
export IMG_OBSERVATORIUM="${REGISTRY}/observatorium:${OCP_DATE}"
export IMG_OBSERVATORIUM_OPERATOR="${REGISTRY}/observatorium-operator:${OCP_DATE}"
export IMG_RBAC_QUERY_PROXY="${REGISTRY}/rbac-query-proxy:${OCP_DATE}"
export IMG_SEARCH_COLLECTOR="${REGISTRY}/search-collector:${OCP_DATE}"
export IMG_SEARCH_INDEXER="${REGISTRY}/search-indexer:${OCP_DATE}"
export IMG_SEARCH_V2_API="${REGISTRY}/search-v2-api:${OCP_DATE}"
export IMG_SEARCH_V2_OPERATOR="${REGISTRY}/search-v2-operator:${OCP_DATE}"
export IMG_SITECONFIG="${REGISTRY}/siteconfig:${OCP_DATE}"
export IMG_SUBCTL="${REGISTRY}/subctl:${OCP_DATE}"
export IMG_SUBMARINER_ADDON="${REGISTRY}/submariner-addon:${OCP_DATE}"
export IMG_SUBMARINER_GATEWAY="${REGISTRY}/submariner-gateway:${OCP_DATE}"
export IMG_SUBMARINER_GLOBALNET="${REGISTRY}/submariner-globalnet:${OCP_DATE}"
export IMG_SUBMARINER_OPERATOR="${REGISTRY}/submariner-operator:${OCP_DATE}"
export IMG_SUBMARINER_ROUTE_AGENT="${REGISTRY}/submariner-route-agent:${OCP_DATE}"
export IMG_VOLSYNC_ADDON_CONTROLLER="${REGISTRY}/volsync-addon-controller:${OCP_DATE}"
export IMG_VOLSYNC="${REGISTRY}/volsync:${OCP_DATE}"
export IMG_CERT_POLICY_CONTROLLER="${REGISTRY}/cert-policy-controller:${OCP_DATE}"
export IMG_THANOS="${REGISTRY}/thanos:${OCP_DATE}"
export IMG_THANOS_RECEIVE_CONTROLLER="${REGISTRY}/thanos-receive-controller:${OCP_DATE}"
export IMG_MEMCACHED="${REGISTRY}/memcached:${OCP_DATE}"
export IMG_PROMETHEUS="${REGISTRY}/prometheus:${OCP_DATE}"
export IMG_PROMETHEUS_CONFIG_RELOADER="${REGISTRY}/prometheus-config-reloader:${OCP_DATE}"
export IMG_PROMETHEUS_ALERTMANAGER="${REGISTRY}/prometheus-alertmanager:${OCP_DATE}"
export IMG_PROMETHEUS_OPERATOR="${REGISTRY}/prometheus-operator:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
export IMG_POSTGRESQL_16="quay.io/sclorg/postgresql-16-c9s:latest"
export IMG_POSTGRESQL_13="quay.io/sclorg/postgresql-13-c9s:latest"
export IMG_REDIS="quay.io/sclorg/redis-7-c9s:latest"
export IMG_CONFIGMAP_RELOADER="$(get_payload_component "configmap-reloader")"
export IMG_KUBE_RBAC_PROXY="$(get_payload_component "kube-rbac-proxy")"
export IMG_CLI_ARTIFACTS="$(get_payload_component "cli-artifacts")"
IMG_CLI="$(get_payload_component "cli")"

IMG_BUNDLE="${REGISTRY}/bundle:${OCP_DATE}"

## Functions

init() {
    submodule_initialize acm-cli release-${OCP_SHORT}
    submodule_initialize cert-policy-controller release-${OCP_SHORT}
    submodule_initialize cluster-backup-operator release-${OCP_SHORT}
    submodule_initialize cluster-permission release-${OCP_SHORT}
    submodule_initialize config-policy-controller release-${OCP_SHORT}
    submodule_initialize console release-${OCP_SHORT}
    submodule_initialize flightctl release-${FLIGHTCTL_RELEASE}
    submodule_initialize flightctl-ui release-${FLIGHTCTL_RELEASE}
    submodule_initialize governance-policy-addon-controller release-${OCP_SHORT}
    submodule_initialize governance-policy-framework-addon release-${OCP_SHORT}
    submodule_initialize governance-policy-propagator release-${OCP_SHORT}
    submodule_initialize grafana release-${OCP_SHORT}
    submodule_initialize insights-client release-${OCP_SHORT}
    submodule_initialize insights-metrics release-${OCP_SHORT}
    submodule_initialize klusterlet-addon-controller release-${OCP_SHORT}
    submodule_initialize kube-state-metrics release-${OCP_SHORT}
    submodule_initialize lighthouse release-${SUBMARINER_RELEASE}
    submodule_initialize memcached_exporter release-${OCP_SHORT}
    submodule_initialize multicloud-integrations release-${OCP_SHORT}
    submodule_initialize multicloud-operators-application release-${OCP_SHORT}
    submodule_initialize multicloud-operators-subscription release-${OCP_SHORT}
    submodule_initialize multicluster-observability-addon release-${OCP_SHORT}
    submodule_initialize multicluster-observability-operator release-${OCP_SHORT}
    submodule_initialize multiclusterhub-operator release-${OCP_SHORT}
    submodule_initialize must-gather release-${OCP_SHORT}
    submodule_initialize node-exporter release-${OCP_SHORT}
    submodule_initialize observatorium-operator release-${OCP_SHORT}
    submodule_initialize observatorium release-${OCP_SHORT}
    submodule_initialize prometheus release-${OCP_SHORT}
    submodule_initialize prometheus-alertmanager release-${OCP_SHORT}
    submodule_initialize prometheus-operator release-${OCP_SHORT}
    submodule_initialize search-collector release-${OCP_SHORT}
    submodule_initialize search-indexer release-${OCP_SHORT}
    submodule_initialize search-v2-api release-${OCP_SHORT}
    submodule_initialize search-v2-operator release-${OCP_SHORT}
    submodule_initialize shipyard release-${SUBMARINER_RELEASE}
    submodule_initialize siteconfig release-${OCP_SHORT}
    submodule_initialize subctl release-${SUBMARINER_RELEASE}
    submodule_initialize submariner release-${SUBMARINER_RELEASE}
    submodule_initialize submariner-addon release-${OCP_SHORT}
    submodule_initialize submariner-operator release-${SUBMARINER_RELEASE}
    submodule_initialize thanos release-${OCP_SHORT}
    submodule_initialize thanos-receive-controller release-${OCP_SHORT}
    submodule_initialize volsync release-${VOLSYNC_RELEASE}
    submodule_initialize volsync-addon-controller release-${OCP_SHORT}
}

deinit() {
    submodule_reset acm-cli release-${OCP_SHORT}
    submodule_reset cert-policy-controller release-${OCP_SHORT}
    submodule_reset cluster-backup-operator release-${OCP_SHORT}
    submodule_reset cluster-permission release-${OCP_SHORT}
    submodule_reset config-policy-controller release-${OCP_SHORT}
    submodule_reset console release-${OCP_SHORT}
    submodule_reset flightctl release-${FLIGHTCTL_RELEASE}
    submodule_reset flightctl-ui release-${FLIGHTCTL_RELEASE}
    submodule_reset governance-policy-addon-controller release-${OCP_SHORT}
    submodule_reset governance-policy-framework-addon release-${OCP_SHORT}
    submodule_reset governance-policy-propagator release-${OCP_SHORT}
    submodule_reset grafana release-${OCP_SHORT}
    submodule_reset insights-client release-${OCP_SHORT}
    submodule_reset insights-metrics release-${OCP_SHORT}
    submodule_reset klusterlet-addon-controller release-${OCP_SHORT}
    submodule_reset kube-state-metrics release-${OCP_SHORT}
    submodule_reset lighthouse release-${SUBMARINER_RELEASE}
    submodule_reset memcached_exporter release-${OCP_SHORT}
    submodule_reset multicloud-integrations release-${OCP_SHORT}
    submodule_reset multicloud-operators-application release-${OCP_SHORT}
    submodule_reset multicloud-operators-subscription release-${OCP_SHORT}
    submodule_reset multicluster-observability-addon release-${OCP_SHORT}
    submodule_reset multicluster-observability-operator release-${OCP_SHORT}
    submodule_reset multiclusterhub-operator release-${OCP_SHORT}
    submodule_reset must-gather release-${OCP_SHORT}
    submodule_reset node-exporter release-${OCP_SHORT}
    submodule_reset observatorium-operator release-${OCP_SHORT}
    submodule_reset observatorium release-${OCP_SHORT}
    submodule_reset prometheus release-${OCP_SHORT}
    submodule_reset prometheus-alertmanager release-${OCP_SHORT}
    submodule_reset prometheus-operator release-${OCP_SHORT}
    submodule_reset search-collector release-${OCP_SHORT}
    submodule_reset search-indexer release-${OCP_SHORT}
    submodule_reset search-v2-api release-${OCP_SHORT}
    submodule_reset search-v2-operator release-${OCP_SHORT}
    submodule_reset shipyard release-${SUBMARINER_RELEASE}
    submodule_reset siteconfig release-${OCP_SHORT}
    submodule_reset subctl release-${SUBMARINER_RELEASE}
    submodule_reset submariner release-${SUBMARINER_RELEASE}
    submodule_reset submariner-addon release-${OCP_SHORT}
    submodule_reset submariner-operator release-${SUBMARINER_RELEASE}
    submodule_reset thanos release-${OCP_SHORT}
    submodule_reset thanos-receive-controller release-${OCP_SHORT}
    submodule_reset volsync release-${VOLSYNC_RELEASE}
    submodule_reset volsync-addon-controller release-${OCP_SHORT}
}

update() {
    function update_submodule() {
        local submodule_path="$1"
        local submodule_branch="$2"

        if [ -d "$submodule_path" ]; then
            git_url=$(git -C "$submodule_path" remote get-url origin)
            echo "Updating submodule: $git_url"
            git -C "$submodule_path" fetch origin "$submodule_branch"
            git -C "$submodule_path" reset --hard "origin/$submodule_branch"
            git -C "$submodule_path" submodule update --init
        else
            echo "Submodule path $submodule_path does not exist."
        fi
    }

    ACM_BRANCH="release-2.15"
    FLIGHTCTL_BRANCH="release-0.8"
    SUBMARINER_BRANCH="release-0.21"

    update_submodule acm-cli $ACM_BRANCH
    update_submodule cert-policy-controller $ACM_BRANCH
    update_submodule cluster-backup-operator $ACM_BRANCH
    update_submodule cluster-permission $ACM_BRANCH
    update_submodule config-policy-controller $ACM_BRANCH
    update_submodule console $ACM_BRANCH
    update_submodule flightctl $FLIGHTCTL_BRANCH
    update_submodule flightctl-ui $FLIGHTCTL_BRANCH
    update_submodule governance-policy-addon-controller $ACM_BRANCH
    update_submodule governance-policy-framework-addon $ACM_BRANCH
    update_submodule governance-policy-propagator $ACM_BRANCH
    update_submodule grafana $ACM_BRANCH
    update_submodule insights-client $ACM_BRANCH
    update_submodule insights-metrics $ACM_BRANCH
    update_submodule klusterlet-addon-controller $ACM_BRANCH
    update_submodule kube-state-metrics $ACM_BRANCH
    update_submodule lighthouse $SUBMARINER_BRANCH
    update_submodule memcached_exporter $ACM_BRANCH
    update_submodule multicloud-integrations $ACM_BRANCH
    update_submodule multicloud-operators-application $ACM_BRANCH
    update_submodule multicloud-operators-subscription $ACM_BRANCH
    update_submodule multicluster-observability-addon $ACM_BRANCH
    update_submodule multicluster-observability-operator $ACM_BRANCH
    update_submodule multiclusterhub-operator $ACM_BRANCH
    update_submodule must-gather $ACM_BRANCH
    update_submodule node-exporter $ACM_BRANCH
    update_submodule observatorium-operator $ACM_BRANCH
    update_submodule observatorium $ACM_BRANCH
    update_submodule prometheus $ACM_BRANCH
    update_submodule prometheus-alertmanager $ACM_BRANCH
    update_submodule prometheus-operator $ACM_BRANCH
    update_submodule search-collector $ACM_BRANCH
    update_submodule search-indexer $ACM_BRANCH
    update_submodule search-v2-api $ACM_BRANCH
    update_submodule search-v2-operator $ACM_BRANCH
    update_submodule shipyard $SUBMARINER_BRANCH
    update_submodule siteconfig $ACM_BRANCH
    update_submodule subctl $SUBMARINER_BRANCH
    update_submodule submariner $SUBMARINER_BRANCH
    update_submodule submariner-addon $ACM_BRANCH
    update_submodule submariner-operator $SUBMARINER_BRANCH
    update_submodule thanos $ACM_BRANCH
    update_submodule thanos-recieve-controller $ACM_BRANCH
    update_submodule volsync release-0.13
    update_submodule volsync-addon-controller $ACM_BRANCH
}

build_containers() {
    podman build -t "${IMG_ACM_CLI}" -f acm-cli.Containerfile --build-arg "CI_VERSION=$OCP_DATE" ../
    podman build -t "${IMG_CLUSTER_BACKUP_OPERATOR}" -f cluster-backup-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CLUSTER_PERMISSION}" -f cluster-permission.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CONFIG_POLICY_CONTROLLER}" -f config-policy-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CONSOLE}" -f console.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_ENDPOINT_MONITORING_OPERATOR}" -f endpoint-monitoring-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_FLIGHTCTL_API}" -f flightctl-api.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_FLIGHTCTL_OCP_UI}" -f flightctl-ocp-ui.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_FLIGHTCTL_PERIODIC}" -f flightctl-periodic.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_FLIGHTCTL_UI}" -f flightctl-ui.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_FLIGHTCTL_WORKER}" -f flightctl-worker.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_FLIGHTCTL_CLI_ARTIFACTS}" -f flightctl-cli-artifacts.Containerfile --build-arg "CI_VERSION=$OCP_DATE" ..
    podman build -t "${IMG_GOVERNANCE_POLICY_ADDON_CONTROLLER}" -f governance-policy-addon-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_GOVERNANCE_POLICY_FRAMEWORK_ADDON}" -f governance-policy-framework-addon.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_GOVERNANCE_POLICY_PROPAGATOR}" -f governance-policy-propagator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_GRAFANA}" -f grafana.Containerfile --build-arg "CI_VERSION=$OCP_DATE" ../
    podman build -t "${IMG_GRAFANA_DASHBOARD_LOADER}" -f grafana-dashboard-loader.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_INSIGHTS_CLIENT}" -f insights-client.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_INSIGHTS_METRICS}" -f insights-metrics.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_KLUSTERLET_ADDON_CONTROLLER}" -f klusterlet-addon-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_KUBE_STATE_METRICS}" -f kube-state-metrics.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_LIGHTHOUSE_AGENT}" -f lighthouse-agent.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "REVISION=$(git -C lighthouse rev-parse HEAD)" .
    podman build -t "${IMG_LIGHTHOUSE_COREDNS}" -f lighthouse-coredns.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MEMCACHED_EXPORTER}" -f memcached-exporter.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_METRICS_COLLECTOR}" -f metrics-collector.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MULTICLOUD_INTEGRATIONS}" -f multicloud-integrations.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MULTICLUSTER_OBSERVABILITY_ADDON}" -f multicluster-observability-addon.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MULTICLUSTER_OBSERVABILITY_OPERATOR}" -f multicluster-observability-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MULTICLUSTER_OPERATORS_APPLICATION}" -f multicluster-operators-application.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MULTICLUSTER_OPERATORS_CHANNEL}" -f multicluster-operators-channel.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MULTICLUSTER_OPERATORS_SUBSCRIPTION}" -f multicluster-operators-subscription.Containerfile --build-arg "CI_VERSION=$OCP_DATE" ../
    podman build -t "${IMG_MULTICLUSTERHUB_OPERATOR}" -f multiclusterhub-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_NETTEST}" -f nettest.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_NODE_EXPORTER}" -f node-exporter.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_OBSERVATORIUM}" -f observatorium.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_OBSERVATORIUM_OPERATOR}" -f observatorium-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_RBAC_QUERY_PROXY}" -f rbac-query-proxy.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_SEARCH_COLLECTOR}" -f search-collector.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_SEARCH_INDEXER}" -f search-indexer.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_SEARCH_V2_API}" -f search-v2-api.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_SEARCH_V2_OPERATOR}" -f search-v2-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_SITECONFIG}" -f siteconfig.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_SUBCTL}" -f subctl.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "CI_REVISION=$(git -C subctl rev-parse HEAD)" .
    podman build -t "${IMG_SUBMARINER_ADDON}" -f submariner-addon.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "CI_REVISION=$(git -C submariner rev-parse HEAD)" .
    podman build -t "${IMG_SUBMARINER_GATEWAY}" -f submariner-gateway.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "CI_REVISION=$(git -C submariner rev-parse HEAD)" .
    podman build -t "${IMG_SUBMARINER_GLOBALNET}" -f submariner-globalnet.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "CI_REVISION=$(git -C submariner rev-parse HEAD)" .
    podman build -t "${IMG_SUBMARINER_OPERATOR}" -f submariner-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "CI_REVISION=$(git -C submariner-operator rev-parse HEAD)" ../
    podman build -t "${IMG_SUBMARINER_ROUTE_AGENT}" -f submariner-route-agent.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "CI_REVISION=$(git -C submariner rev-parse HEAD)" .
    podman build -t "${IMG_VOLSYNC_ADDON_CONTROLLER}" -f volsync-addon-controller.Containerfile --build-arg "VERSION=$OCP_DATE" .
    podman build -t "${IMG_VOLSYNC}" -f volsync.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_CERT_POLICY_CONTROLLER}" -f cert-policy-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_THANOS}" -f thanos.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_THANOS_RECEIVE_CONTROLLER}" -f thanos-receive-controller.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MEMCACHED}" -f memcached.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_PROMETHEUS}" -f prometheus.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_PROMETHEUS_CONFIG_RELOADER}" -f prometheus-config-reloader.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_PROMETHEUS_ALERTMANAGER}" -f prometheus-alertmanager.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_PROMETHEUS_OPERATOR}" -f prometheus-operator.Containerfile --build-arg "CI_VERSION=$OCP_DATE" .
    podman build -t "${IMG_MUST_GATHER}" -f must-gather.Containerfile --build-arg "CI_VERSION=$OCP_DATE" --build-arg "IMG_CLI=$IMG_CLI" ../
}

push_containers() {
    push_all_images
}

build_bundle() {
    convert_all_images_to_digest

    export VERSION=$OCP_DATE
    export ENV_OVERRIDES="$(envsubst < operand-env.yaml)"
    export RELATED_IMAGES="$(envsubst < related-images.yaml)"

    pushd multiclusterhub-operator

    yq e -i 'select(.kind == "Deployment").spec.template.spec.containers[0].env += env(ENV_OVERRIDES)' config/manager/manager.yaml

    # Change package from open-cluster-management to advanced-cluster-management
    BUNDLE_METADATA_OPTS="$BUNDLE_METADATA_OPTS --package advanced-cluster-management"
    rm -rf bundle
    make bundle "VERSION=$OCP_DATE" "BUNDLE_METADATA_OPTS=$BUNDLE_METADATA_OPTS" BUNDLE_IMG=$IMG_BUNDLE IMG=$IMG_MULTICLUSTERHUB_OPERATOR

    yq e -i '.spec.relatedImages += env(RELATED_IMAGES)' bundle/manifests/advanced-cluster-management.clusterserviceversion.yaml

    podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
    podman push "${IMG_BUNDLE}"

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
