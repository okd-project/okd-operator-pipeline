#!/bin/bash

MAJOR=1
MINOR=2

source ../common.sh

REGISTRY="${BASE_REGISTRY}/cluster-observability"

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_CLUSTER_HEALTH_ANALYZER="${REGISTRY}/cluster-health-analyzer:${OCP_DATE}"
IMG_KORREL8R="${REGISTRY}/korrel8r:${OCP_DATE}"
IMG_PROMETHEUS_OPERATOR="${REGISTRY}/prometheus-operator:${OCP_DATE}"
IMG_PROMETHEUS="${REGISTRY}/prometheus:${OCP_DATE}"
IMG_PROMETHEUS_CONFIG_RELOADER="${REGISTRY}/prometheus-config-reloader:${OCP_DATE}"
IMG_PROMETHEUS_ALERTMANAGER="${REGISTRY}/prometheus-alertmanager:${OCP_DATE}"
IMG_PROMETHEUS_OPERATOR_ADMISSION_WEBHOOK="${REGISTRY}/prometheus-operator-admission-webhook:${OCP_DATE}"
IMG_PERSES="${REGISTRY}/perses:${OCP_DATE}"
IMG_PERSES_OPERATOR="${REGISTRY}/perses-operator:${OCP_DATE}"
IMG_THANOS="${REGISTRY}/thanos:${OCP_DATE}"
IMG_DASHBOARDS_CONSOLE_PLUGIN="${REGISTRY}/dashboards-console-plugin:${OCP_DATE}"
IMG_DISTRUBUTED_TRACING_CONSOLE_PLUGIN="${REGISTRY}/distributed-tracing-console-plugin:${OCP_DATE}"
IMG_LOGGING_CONSOLE_PLUGIN="${REGISTRY}/logging-console-plugin:${OCP_DATE}"
IMG_MONITORING_CONSOLE_PLUGIN="${REGISTRY}/monitoring-console-plugin:${OCP_DATE}"
IMG_TROUBLESHOOTING_CONSOLE_PLUGIN="${REGISTRY}/troubleshooting-console-plugin:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

#submodule_initialize operator release-${OCP_SHORT}

# Build images
#podman build -t "${IMG_OPERATOR}" -f manifests/Dockerfile.obo manifests
#podman build -t "${IMG_CLUSTER_HEALTH_ANALYZER}" -f manifests/Dockerfile.cluster-health-analyzer manifests
#podman build -t "${IMG_KORREL8R}" -f manifests/Dockerfile.korrel8r manifests
#podman build -t "${IMG_PROMETHEUS_OPERATOR}" -f manifests/Dockerfile.prom-op manifests
#podman build -t "${IMG_PROMETHEUS}" -f manifests/Dockerfile.prometheus manifests
podman build -t "${IMG_PROMETHEUS_CONFIG_RELOADER}" -f manifests/Dockerfile.prometheus-config-reloader manifests
podman build -t "${IMG_PROMETHEUS_ALERTMANAGER}" -f manifests/Dockerfile.alertmanager manifests
podman build -t "${IMG_PROMETHEUS_OPERATOR_ADMISSION_WEBHOOK}" -f manifests/Dockerfile.p-o-admission-webhook manifests
podman build -t "${IMG_PERSES}" -f manifests/Dockerfile.perseus manifests
podman build -t "${IMG_PERSES_OPERATOR}" -f manifests/Dockerfile.perseus-operator manifests
podman build -t "${IMG_THANOS}" -f manifests/Dockerfile.thanos manifests
podman build -t "${IMG_DASHBOARDS_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-dashboards manifests
podman build -t "${IMG_DISTRUBUTED_TRACING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-distributed-tracing manifests
podman build -t "${IMG_LOGGING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-logging manifests
podman build -t "${IMG_MONITORING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-monitoring manifests
podman build -t "${IMG_TROUBLESHOOTING_CONSOLE_PLUGIN}" -f manifests/Dockerfile.ui-troubleshooting-panel manifests

# Push images
#podman push "${IMG_OPERATOR}"
#podman push "${IMG_CLUSTER_HEALTH_ANALYZER}"
#podman push "${IMG_KORREL8R}"
#podman push "${IMG_PROMETHEUS_OPERATOR}"
#podman push "${IMG_PROMETHEUS}"
#podman push "${IMG_PROMETHEUS_CONFIG_RELOADER}"
#podman push "${IMG_PROMETHEUS_ALERTMANAGER}"
#podman push "${IMG_PROMETHEUS_OPERATOR_ADMISSION_WEBHOOK}"
#podman push "${IMG_PERSES}"
#podman push "${IMG_PERSES_OPERATOR}"
#podman push "${IMG_THANOS}"
#podman push "${IMG_DASHBOARDS_CONSOLE_PLUGIN}"
#podman push "${IMG_DISTRUBUTED_TRACING_CONSOLE_PLUGIN}"
#podman push "${IMG_LOGGING_CONSOLE_PLUGIN}"
#podman push "${IMG_MONITORING_CONSOLE_PLUGIN}"
#podman push "${IMG_TROUBLESHOOTING_CONSOLE_PLUGIN}"
