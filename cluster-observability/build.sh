#!/bin/bash

NAMESPACE="cluster-observability"
MAJOR=1
MINOR=2
DATE=2025-08-05-110414

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_CLUSTER_HEALTH_ANALYZER="${REGISTRY}/cluster-health-analyzer:${OCP_DATE}"
export IMG_KORREL8R="${REGISTRY}/korrel8r:${OCP_DATE}"
export IMG_PROMETHEUS_OPERATOR="${REGISTRY}/prometheus-operator:${OCP_DATE}"
export IMG_PROMETHEUS="${REGISTRY}/prometheus:${OCP_DATE}"
export IMG_PROMETHEUS_CONFIG_RELOADER="${REGISTRY}/prometheus-config-reloader:${OCP_DATE}"
export IMG_PROMETHEUS_ALERTMANAGER="${REGISTRY}/prometheus-alertmanager:${OCP_DATE}"
export IMG_PROMETHEUS_OPERATOR_ADMISSION_WEBHOOK="${REGISTRY}/prometheus-operator-admission-webhook:${OCP_DATE}"
export IMG_PERSES="${REGISTRY}/perses:${OCP_DATE}"
export IMG_PERSES_OPERATOR="${REGISTRY}/perses-operator:${OCP_DATE}"
export IMG_THANOS="${REGISTRY}/thanos:${OCP_DATE}"
export IMG_DASHBOARDS_CONSOLE_PLUGIN="${REGISTRY}/dashboards-console-plugin:${OCP_DATE}"
export IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN="${REGISTRY}/distributed-tracing-console-plugin:${OCP_DATE}"
export IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF4="${REGISTRY}/distributed-tracing-console-plugin-pf4:${OCP_DATE}"
export IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF5="${REGISTRY}/distributed-tracing-console-plugin-pf5:${OCP_DATE}"
export IMG_LOGGING_CONSOLE_PLUGIN="${REGISTRY}/logging-console-plugin:${OCP_DATE}"
export IMG_LOGGING_CONSOLE_PLUGIN_PF4="${REGISTRY}/logging-console-plugin-pf4:${OCP_DATE}"
export IMG_MONITORING_CONSOLE_PLUGIN="${REGISTRY}/monitoring-console-plugin:${OCP_DATE}"
export IMG_MONITORING_CONSOLE_PLUGIN_PF5="${REGISTRY}/monitoring-console-plugin-pf5:${OCP_DATE}"
export IMG_TROUBLESHOOTING_CONSOLE_PLUGIN="${REGISTRY}/troubleshooting-console-plugin:${OCP_DATE}"

BUNDLE_VERSION=1.2.0-2025-08-05-110415
IMG_BUNDLE="${REGISTRY}/operator-bundle:${BUNDLE_VERSION}"

#submodule_initialize operator release-${OCP_SHORT}

# Build images
#podman build -t "${IMG_OPERATOR}" -f manifests/Dockerfile.obo manifests
#podman build -t "${IMG_CLUSTER_HEALTH_ANALYZER}" -f manifests/Dockerfile.cluster-health-analyzer manifests
#podman build -t "${IMG_KORREL8R}" -f manifests/Dockerfile.korrel8r manifests
#podman build -t "${IMG_PROMETHEUS_OPERATOR}" -f manifests/Dockerfile.prom-op manifests
#podman build -t "${IMG_PROMETHEUS}" -f manifests/Dockerfile.prometheus manifests
#podman build -t "${IMG_PROMETHEUS_CONFIG_RELOADER}" -f manifests/Dockerfile.prometheus-config-reloader manifests
#podman build -t "${IMG_PROMETHEUS_ALERTMANAGER}" -f manifests/Dockerfile.alertmanager manifests
#podman build -t "${IMG_PROMETHEUS_OPERATOR_ADMISSION_WEBHOOK}" -f manifests/Dockerfile.p-o-admission-webhook manifests
#podman build -t "${IMG_PERSES}" -f manifests/Dockerfile.perses manifests
#podman build -t "${IMG_PERSES_OPERATOR}" -f manifests/Dockerfile.perses-operator manifests
#podman build -t "${IMG_THANOS}" -f manifests/Dockerfile.thanos manifests
#podman build -t "${IMG_DASHBOARDS_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-dashboards manifests
#podman build -t "${IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-distributed-tracing manifests
#podman build -t "${IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF4}" -f manifests/Dockerfile.ui-distributed-tracing-pf4 manifests
#podman build -t "${IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF5}" -f manifests/Dockerfile.ui-distributed-tracing-pf5 manifests
#podman build -t "${IMG_LOGGING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-logging manifests
#podman build -t "${IMG_LOGGING_CONSOLE_PLUGIN_PF4}" -f manifests/Dockerfile.ui-logging-pf4 manifests
#podman build -t "${IMG_MONITORING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-monitoring manifests
#podman build -t "${IMG_MONITORING_CONSOLE_PLUGIN_PF5}" -f manifests/Dockerfile.ui-monitoring-pf5 manifests
#podman build -t "${IMG_TROUBLESHOOTING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-troubleshooting-panel manifests

# Push images
#push_all_images

convert_all_images_to_digest

pushd manifests/observability-operator

function add_manager_cli_arg() {
  local cli_arg="$1"

  export MULTI_LINE="- patch: |-
    - op: add
      path: /spec/template/spec/containers/0/args/-
      value: $cli_arg
  target:
    group: apps
    kind: Deployment
    version: v1
  "

  yq -i ".patches += env(MULTI_LINE)" deploy/operator/kustomization.yaml
}

function override_image() {
    local image_name="$1"
    local image="$2"

    add_manager_cli_arg "--images=$image_name=$image"
}

yq -i ".spec.template.spec.containers[0].image = \"${IMG_PERSES_OPERATOR}\"" deploy/perses/perses-operator-deployment.yaml
yq -i ".patches = []" deploy/operator/kustomization.yaml

override_image "prometheus" "${IMG_PROMETHEUS}"
override_image "alertmanager" "${IMG_PROMETHEUS_ALERTMANAGER}"
override_image "thanos" "${IMG_THANOS}"
override_image "ui-dashboards" "${IMG_DASHBOARDS_CONSOLE_PLUGIN}"
override_image "ui-troubleshooting-panel" "${IMG_TROUBLESHOOTING_CONSOLE_PLUGIN}"
override_image "ui-distributed-tracing-pf4" "${IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF4}"
override_image "ui-distributed-tracing-pf5" "${IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF5}"
override_image "ui-distributed-tracing" "${IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN}"
override_image "ui-logging-pf4" "${IMG_LOGGING_CONSOLE_PLUGIN_PF4}"
override_image "ui-logging" "${IMG_LOGGING_CONSOLE_PLUGIN}"
override_image "korrel8r" "${IMG_KORREL8R}"
override_image "health-analyzer" "${IMG_CLUSTER_HEALTH_ANALYZER}"
override_image "ui-monitoring-pf5" "${IMG_MONITORING_CONSOLE_PLUGIN_PF5}"
override_image "ui-monitoring" "${IMG_MONITORING_CONSOLE_PLUGIN}"
override_image "perses" "${IMG_PERSES}"

add_manager_cli_arg "--openshift.enabled=true"

rm -r bundle || true

make bundle "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
  "OPERATOR_IMG=${IMG_OPERATOR}" \
  "VERSION=${BUNDLE_VERSION}" \
  "BUNDLE_IMG=${IMG_BUNDLE}" \
  "PACKAGE_NAME=cluster-observability-operator"

csv_file="bundle/manifests/cluster-observability-operator.clusterserviceversion.yaml"
yq -i '.metadata.annotations."features.operators.openshift.io/disconnected" = "true"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/fips-compliant" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/proxy-aware" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/tls-profiles" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/token-auth-aws" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/token-auth-azure" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/token-auth-gcp" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/cnf" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/cni" = "false"' "$csv_file"
yq -i '.metadata.annotations."features.operators.openshift.io/csi" = "false"' "$csv_file"
yq -i '.metadata.annotations.support = "OKD Community"' "$csv_file"
yq -i '.metadata.labels."operatorframework.io/arch.amd64" = "supported"' "$csv_file"

#yq -i '(.spec.relatedImages += [{"name":"cluster-observability-operator", "image": strenv(IMG_OPERATOR)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"prometheus-config-reloader", "image": strenv(IMG_PROMETHEUS_CONFIG_RELOADER)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"alertmanager", "image": strenv(IMG_PROMETHEUS_ALERTMANAGER)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"prometheus", "image": strenv(IMG_PROMETHEUS)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"thanos", "image": strenv(IMG_THANOS)}])' "$csv_file"
#yq -i '(.spec.relatedImages += [{"name":"prometheus-operator-admission-webhook", "image": strenv(IMG_PROMETHEUS_OPERATOR_ADMISSION_WEBHOOK)}])' "$csv_file"
#yq -i '(.spec.relatedImages += [{"name":"prometheus-operator", "image": strenv(IMG_PROMETHEUS_OPERATOR)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-dashboards", "image": strenv(IMG_DASHBOARDS_CONSOLE_PLUGIN)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-tracing", "image": strenv(IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-tracing-pf5", "image": strenv(IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF5)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-tracing-pf4", "image": strenv(IMG_DISTRIBUTED_TRACING_CONSOLE_PLUGIN_PF5)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-logging", "image": strenv(IMG_LOGGING_CONSOLE_PLUGIN)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-logging-pf4", "image": strenv(IMG_LOGGING_CONSOLE_PLUGIN_PF4)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-troubleshooting", "image": strenv(IMG_TROUBLESHOOTING_CONSOLE_PLUGIN)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-monitoring", "image": strenv(IMG_MONITORING_CONSOLE_PLUGIN)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"ui-monitoring-pf5", "image": strenv(IMG_MONITORING_CONSOLE_PLUGIN_PF5)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"korrel8r", "image": strenv(IMG_KORREL8R)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"cluster-health-analyzer", "image": strenv(IMG_CLUSTER_HEALTH_ANALYZER)}])' "$csv_file"
yq -i '(.spec.relatedImages += [{"name":"perses", "image": strenv(IMG_PERSES)}])' "$csv_file"
#yq -i '(.spec.relatedImages += [{"name":"perses-operator", "image": strenv(IMG_PERSES_OPERATOR)}])' "$csv_file"

yq -i '.spec.displayName = "Cluster Observability Operator"' "$csv_file"
yq -i '.provider.name = "OKD Community"' "$csv_file"
sed -i -r "s|operatorframework.io/suggested-namespace: observability-operator|operatorframework.io/suggested-namespace: openshift-cluster-observability-operator|" "$csv_file"

export DESC=$(cat << EOF
Cluster Observability Operator is a Go based Kubernetes operator to easily setup and manage various observability tools.
### Supported Features
- Setup multiple Highly Available Monitoring stack using Prometheus, Alertmanager and Thanos Querier
- Customizable configuration for managing Prometheus deployments
- Customizable configuration for managing Alertmanager deployments
- Customizable configuration for managing Thanos Querier deployments
- Setup console plugins
- Setup korrel8r
- Setup Perses
- Setup Cluster Health Analyzer
### Documentation
- **[Documentation](https://docs.okd.io/latest/observability/cluster_observability_operator/cluster-observability-operator-overview.html)**
###  License
Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
EOF
)

yq -i '.spec.description = strenv(DESC)' "$csv_file"

podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
podman push "${IMG_BUNDLE}"

popd
