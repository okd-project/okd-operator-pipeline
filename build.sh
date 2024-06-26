#!/bin/bash

NAMESPACE=${NAMESPACE:-okd-team}
IMAGE_REGISTRY=${IMAGE_REGISTRY:-quay.io}
REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE:-okderators}
BASE_IMAGE_REGISTRY=${BASE_IMAGE_REGISTRY:-$IMAGE_REGISTRY/$REGISTRY_NAMESPACE}
CHANNEL=${CHANNEL:-alpha}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL:-alpha}
CHANNELS=${CHANNELS:-alpha}
BUILD_IMAGE=${BUILD_IMAGE:-quay.io/okderators/bundle-tools:vdev}
ENABLE_TIMESTAMP=${ENABLE_TIMESTAMP:-true}
CATALOG_SOURCE=${CATALOG_SOURCE:-okderators}
CATALOG_NAMESPACE=${CATALOG_NAMESPACE:-openshift-marketplace}

# Account for edge cases
case $1 in
  "kube-rbac-proxy"|"oauth-proxy")
    VERSION=${VERSION:-4.15}
    ENABLE_TIMESTAMP=false
    ;;
  "vector"|"log-file-metric-exporter"|"fluentd"|"logging-view-plugin"|"cluster-logging-operator"|"loki")
    VERSION=${VERSION:-5.9.0}
    ;;
  *)
    VERSION=${VERSION:-4.15.0}
    ;;
esac

# Check if enabled timestamp is set to true
if [ "$ENABLE_TIMESTAMP" = "true" ]; then
  VERSION="${VERSION}-$(date "+%Y-%m-%d-%H%M%S")"
fi

echo "Using version: $VERSION"

function build_operand() {
  NAME=$3
  ENV_MAP="$ENV $4"
  tkn pipeline start operand \
    --prefix-name $NAME \
    --param repo-url=$1 \
    --param repo-ref=$2 \
    --param base-image-registry=$BASE_IMAGE_REGISTRY \
    --param image-name=$3 \
    --param version=$VERSION \
    --param make-image=$BUILD_IMAGE \
    --param env-map="$ENV_MAP" \
    --workspace name=workspace,claimName=$NAME-volume \
    --workspace name=patches,config=$NAME-patch \
    --pod-template pod-template.yaml \
    -n $NAMESPACE \
    --showlog
}

function build_operator() {
  NAME=$3
  if [ -z "$ENV" ]; then
    ENV_MAP="$4"
  else
    ENV_MAP="$ENV $4"
  fi
  tkn pipeline start operator \
    --prefix-name $NAME \
    --param repo-url=$1 \
    --param repo-ref=$2 \
    --param base-image-registry=$BASE_IMAGE_REGISTRY \
    --param image-name=$3 \
    --param image-version=$VERSION \
    --param channel=$CHANNEL \
    --param default-channel=$DEFAULT_CHANNEL \
    --param make-image=$BUILD_IMAGE \
    --param env-map="$ENV_MAP" \
    --workspace name=workspace,claimName=$NAME-volume \
    --workspace name=patches,config=$NAME-patch \
    --pod-template pod-template.yaml \
    -n $NAMESPACE \
    --showlog
}

function build_image() {
    tkn pipeline start image-build \
          --param repo-url=$1 \
          --param repo-ref=$2 \
          --param base-image-registry=$BASE_IMAGE_REGISTRY \
          --param image-name=$3 \
          --param image-version=dev \
          --param Dockerfile=$4 \
          --workspace name=workspace,claimName=bundle-tools-volume \
          --workspace name=patches,config=bundle-tools-patch \
          --pod-template pod-template.yaml \
          -n $NAMESPACE \
          --showlog
}

case $1 in
  "bundle-tools")
    build_image https://github.com/okd-project/okd-operator-pipeline ocs bundle-tools images/tools.Containerfile
    ;;
  "git-image")
    build_image https://github.com/okd-project/okd-operator-pipeline ocs git images/git.Containerfile
    ;;
  "kube-rbac-proxy")
    build_operand https://github.com/openshift/kube-rbac-proxy "${BRANCH:-release-4.15}" kube-rbac-proxy
    ;;
  "oauth-proxy")
    build_operand https://github.com/openshift/oauth-proxy "${BRANCH:-release-4.15}" oauth-proxy
    ;;
  "gitops-console-plugin")
    build_operand https://github.com/redhat-developer/gitops-console-plugin "${BRANCH:-main}" gitops-console-plugin
    ;;
  "gitops-backend")
    build_operand https://github.com/redhat-developer/gitops-backend "${BRANCH:-master}" gitops-backend
    ;;
  "gitops-operator")
    CONSOLE_IMAGE=${CONSOLE_IMAGE:-quay.io/okderators/gitops-console-plugin}
    CONSOLE_IMAGE_TAG=${CONSOLE_IMAGE_TAG:-v0.0.1}
    BACKEND_IMG=${BACKEND_IMG:-quay.io/okderators/gitops-backend:v0.0.1}
    build_operator https://github.com/redhat-developer/gitops-operator "${BRANCH:-v1.12}" gitops-operator \
      "CONSOLE_IMAGE=$CONSOLE_IMAGE CONSOLE_IMAGE_TAG=$CONSOLE_IMAGE_TAG BACKEND_IMG=$BACKEND_IMG"
    ;;
  "noobaa-core")
    build_operand https://github.com/red-hat-storage/noobaa-core "${BRANCH:-release-4.15}" noobaa-core
    ;;
  "noobaa-operator")
    NOOBAA_DB_IMAGE=${NOOBAA_DB_IMAGE:-quay.io/sclorg/postgresql-16-c9s:latest}
    NOOBAA_PSQL_12_IMAGE=${NOOBAA_PSQL_12_IMAGE:-quay.io/sclorg/postgresql-12-c8s:latest}
    NOOBAA_CORE_IMAGE=${NOOBAA_CORE_IMAGE:-quay.io/okderators/noobaa-core:dev}
    SKIP_RANGE=${SKIP_RANGE:-">=4.2.0<$VERSION"}
    REPLACES=${REPLACES:-"null"}
    CSV_NAME=${CSV_NAME:-noobaa-operator.v${VERSION}}
    build_operator https://github.com/red-hat-storage/noobaa-operator "${BRANCH:-release-4.15}" noobaa-operator \
      "CORE_IMAGE=$NOOBAA_CORE_IMAGE DB_IMAGE=$NOOBAA_DB_IMAGE SKIP_RANGE=$SKIP_RANGE REPLACES=$REPLACES CSV_NAME=$CSV_NAME PSQL_12_IMAGE=$NOOBAA_PSQL_12_IMAGE obc-crd=owned"
    ;;
  "loki")
    build_operator https://github.com/openshift/loki "${BRANCH:-release-5.9}" loki
    ;;
  "vector")
    build_operand https://github.com/ViaQ/vector "${BRANCH:-release-5.9}" vector
    ;;
  "fluentd")
    build_operand https://github.com/ViaQ/logging-fluentd "${BRANCH:-v1.16.x}" fluentd
    ;;
  "logging-view-plugin")
    build_operand https://github.com/openshift/logging-view-plugin "${BRANCH:-release-5.9}" logging-view-plugin
    ;;
  "log-file-metric-exporter")
    build_operand https://github.com/ViaQ/log-file-metric-exporter "${BRANCH:-release-5.9}" log-file-metric-exporter
    ;;
  "cluster-logging-operator")
    FLUENTD=${FLUENTD:-quay.io/okderators/fluentd:latest}
    VECTOR=${VECTOR:-quay.io/okderators/vector:latest}
    LOG_FILE_METRIC_EXPORTER=${LOG_FILE_METRIC_EXPORTER:-quay.io/okderators/log-file-metric-exporter:latest}
    LOGGING_VIEW_PLUGIN=${LOGGING_VIEW_PLUGIN:-quay.io/okderators/logging-view-plugin:latest}
    build_operator https://github.com/openshift/cluster-logging-operator "${BRANCH:-release-5.9}" cluster-logging-operator \
      "IMAGE_LOGGING_FLUENTD=$FLUENTD IMAGE_LOGGING_VECTOR=$VECTOR IMAGE_LOGFILEMETRICEXPORTER=$LOG_FILE_METRIC_EXPORTER IMAGE_LOGGING_CONSOLE_PLUGIN=$LOGGING_VIEW_PLUGIN"
    ;;
  "ocs-operator")
    NOOBAA_DB_IMG=${NOOBAA_DB_IMG:-quay.io/sclorg/postgresql-16-c9s:latest}
    NOOBAA_CORE_IMG=${NOOBAA_CORE_IMG:-quay.io/okderators/noobaa-core:dev}
    ROOK_VERSION=${ROOK_VERSION:-dev}
    ROOK_IMG=${ROOK_IMG:-quay.io/okderators/rook-ceph:${ROOK_VERSION}}
    ROOK_CSIADDONS_IMG=${ROOK_CSIADDONS_IMG:-quay.io/okderators/csi-k8s-sidecar:dev}
    CEPH_IMG=${CEPH_IMG:-quay.io/ceph/ceph:v18.2.2}
    OAUTH_PROXY_IMG=${OAUTH_PROXY_IMG:-quay.io/openshift/origin-oauth-proxy:4.15}
    build_operator https://github.com/red-hat-storage/ocs-operator "${BRANCH:-release-4.15}" ocs-operator \
      "NOOBAA_CORE_IMG=$NOOBAA_CORE_IMG NOOBAA_DB_IMG=$NOOBAA_DB_IMG ROOK_IMG=$ROOK_IMG CEPH_IMG=$CEPH_IMG OAUTH_PROXY_IMG=$OAUTH_PROXY_IMG ROOK_CSIADDONS_IMAGE=$ROOK_CSIADDONS_IMG"
    ;;
  "ocs-metrics-exporter")
    build_operand https://github.com/red-hat-storage/ocs-operator "${BRANCH:-release-4.15}" ocs-metrics-exporter
    ;;
  "odf-console")
    build_operand https://github.com/red-hat-storage/odf-console "${BRANCH:-release-4.15}" odf-console
    ;;
  "odf-operator")
    OCS_VERSION=${OCS_VERSION:dev}
    NOOBAA_VERSION=${NOOBAA_VERSION:dev}
    ODF_CONSOLE_VERSION=${ODF_CONSOLE_VERSION:dev}
    CSIADDONS_VERSION=${CSIADDONS_VERSION:dev}
    KUBE_RBAC_PROXY_IMAGE=${KUBE_RBAC_PROXY_IMAGE:-quay.io/okderators/kube-rbac-proxy:4.15}

    build_operator https://github.com/red-hat-storage/odf-operator "${BRANCH:-release-4.15}" odf-operator \
    "IMAGE_REGISTRY=$IMAGE_REGISTRY REGISTRY_NAMESPACE=$REGISTRY_NAMESPACE OCS_BUNDLE_IMG_TAG=$OCS_VERSION\
 NOOBAA_BUNDLE_IMG_TAG=$NOOBAA_VERSION CSIADDONS_BUNDLE_IMG_NAME=csi-addons-bundle\
 CSIADDONS_BUNDLE_IMG_TAG=$CSIADDONS_VERSION ODF_CONSOLE_IMG_TAG=$ODF_CONSOLE_VERSION\
 OPERATOR_CATALOGSOURCE=$CATALOG_SOURCE OPERATOR_CATALOG_NAMESPACE=$CATALOG_NAMESPACE\
 OSE_KUBE_RBAC_PROXY_IMG=$KUBE_RBAC_PROXY_IMAGE"
    ;;
  "rook-ceph")
    build_operand https://github.com/red-hat-storage/rook "${BRANCH:-release-4.15}" rook-ceph
    ;;
  "local-storage-operator")
    KUBE_RBAC_PROXY_IMAGE=${KUBE_RBAC_PROXY_IMAGE:-quay.io/okderators/kube-rbac-proxy:4.15}
    build_operator https://github.com/openshift/local-storage-operator "${BRANCH:-release-4.15}" local-storage-operator \
      "KUBE_RBAC_PROXY_IMAGE=$KUBE_RBAC_PROXY_IMAGE"
    ;;
  "csi-addons")
    build_operator https://github.com/red-hat-storage/kubernetes-csi-addons "${BRANCH:-release-4.15}" csi-addons
    ;;
  *)
    echo "Usage: $0 <operand/operator name>"
    exit 1
    ;;
esac
