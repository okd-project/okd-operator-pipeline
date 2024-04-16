#!/bin/bash

NAMESPACE=${NAMESPACE:-okd-team}
IMAGE_REGISTRY=${IMAGE_REGISTRY:-quay.io}
REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE:-okderators}
BASE_IMAGE_REGISTRY=${BASE_IMAGE_REGISTRY:-$IMAGE_REGISTRY/$REGISTRY_NAMESPACE}
CHANNEL=${CHANNEL:-alpha}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL:-alpha}
CHANNELS=${CHANNELS:-alpha}
VERSION=${VERSION:-4.15.0}
BUILD_IMAGE=${BUILD_IMAGE:-quay.io/okderators/bundle-tools:vdev}
ENABLE_TIMESTAMP=${ENABLE_TIMESTAMP:-true}

# Check if enabled timestamp is set to true
if [ "$ENABLE_TIMESTAMP" = "true" ] && [ "$1" != "kube-rbac-proxy" ] && [ "$1" != "oauth-proxy" ]; then
  VERSION="${VERSION}-$(date "+%Y-%m-%d-%H%M%S")"
fi

echo "Using version: $VERSION"

function build_operand() {
  NAME=$3
  ENV_MAP="$ENV $4"
  tkn pipeline start operand \
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
  ENV_MAP="$ENV $4"
  tkn pipeline start operator \
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
  echo "$ENV_MAP"
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
    NOOBAA_CORE_IMAGE=${NOOBAA_CORE_IMAGE:-quay.io/okderators/noobaa-core:dev}
    SKIP_RANGE=${SKIP_RANGE:-"<=4.15.0"}
    REPLACES=${REPLACES:-"4.15.0"}
    CSV_NAME=${CSV_NAME:-noobaa-operator.v${VERSION}}
    build_operator https://github.com/red-hat-storage/noobaa-operator "${BRANCH:-release-4.15}" noobaa-operator \
      "CORE_IMAGE=$NOOBAA_CORE_IMAGE DB_IMAGE=$NOOBAA_DB_IMAGE SKIP_RANGE=$SKIP_RANGE REPLACES=$REPLACES CSV_NAME=$CSV_NAME"
    ;;
  "logging-view-plugin")
    build_operand https://github.com/openshift/logging-view-plugin "${BRANCH:-main}" logging-view-plugin
    ;;
  "log-file-metric-exporter")
    build_operand https://github.com/ViaQ/log-file-metric-exporter "${BRANCH:-release-5.8}" log-file-metric-exporter
    ;;
  "ocs-operator")
    CSV_VERSION=${CSV_VERSION:-999.999.999}
    NOOBAA_DB_IMAGE=${NOOBAA_DB_IMAGE:-quay.io/sclorg/postgresql-16-c9s:latest}
    NOOBAA_CORE_IMAGE=${NOOBAA_CORE_IMAGE:-quay.io/okderators/noobaa-core:dev}
    ROOK_IMAGE=${ROOK_IMAGE:-quay.io/okderators/rook-ceph:dev}
    CEPH_IMAGE=${CEPH_IMAGE:-quay.io/ceph/ceph:v18.2.1}
    NOOBAA_BUNDLE_FULL_IMAGE_NAME=${NOOBAA_BUNDLE_FULL_IMAGE_NAME:-quay.io/okderators/noobaa-operator-bundle:dev}
    OCS_IMAGE=${OCS_IMAGE:-quay.io/okderators/ocs-operator:dev}
    OCS_METRICS_EXPORTER_IMAGE=${OCS_METRICS_EXPORTER_IMAGE:-quay.io/okderators/ocs-metrics-exporter:dev}
    UX_BACKEND_OAUTH_IMAGE=${UX_BACKEND_OAUTH_IMAGE:-quay.io/openshift/origin-oauth-proxy:latest}
    build_operator https://github.com/red-hat-storage/ocs-operator "${BRANCH:-release-4.15}" ocs-operator \
      "CSV_VERSION=$CSV_VERSION} NOOBAA_CORE_IMAGE=$NOOBAA_CORE_IMAGE NOOBAA_DB_IMAGE=$NOOBAA_DB_IMAGE ROOK_IMAGE=$ROOK_IMAGE CEPH_IMAGE=$CEPH_IMAGE NOOBAA_BUNDLE_FULL_IMAGE_NAME=$NOOBAA_BUNDLE_FULL_IMAGE_NAME OCS_IMAGE=$OCS_IMAGE OCS_METRICS_EXPORTER_IMAGE=$OCS_METRICS_EXPORTER_IMAGE UX_BACKEND_OAUTH_IMAGE=$UX_BACKEND_OAUTH_IMAGE"
    ;;
  "ocs-metrics-exporter")
    build_operand https://github.com/red-hat-storage/ocs-operator "${BRANCH:-release-4.15}" ocs-metrics-exporter
    ;;
  "odf-console")
    build_operand https://github.com/red-hat-storage/odf-console "${BRANCH:-release-4.15}" odf-console
    ;;
  "odf-operator")
    OCS_BUNDLE_IMG=${OCS_BUNDLE_IMG:-quay.io/okderators/ocs-operator-bundle:dev}
    NOOBAA_BUNDLE_IMG=${NOOBAA_BUNDLE_IMG:-quay.io/okderators/noobaa-operator-bundle:dev}
    ODF_CONSOLE_IMAGE=${ODF_CONSOLE_IMAGE:-quay.io/okderators/odf-console:dev}
    build_operator https://github.com/red-hat-storage/odf-operator "${BRANCH:-release-4.15}" odf-operator \
      "IMAGE_REGISTRY=$IMAGE_REGISTRY REGISTRY_NAMESPACE=$REGISTRY_NAMESPACE OCS_BUNDLE_IMG=$OCS_BUNDLE_IMG NOOBAA_BUNDLE_IMG=$NOOBAA_BUNDLE_IMG ODF_CONSOLE_IMAGE=$ODF_CONSOLE_IMAGE"
    ;;
  "rook-ceph")
    build_operand https://github.com/red-hat-storage/rook "${BRANCH:-release-4.15}" rook-ceph
    ;;
  "local-storage-operator")
    KUBE_RBAC_PROXY_IMAGE=${KUBE_RBAC_PROXY_IMAGE:-quay.io/okderators/kube-rbac-proxy:4.15}
    build_operator https://github.com/openshift/local-storage-operator "${BRANCH:-release-4.15}" local-storage-operator \
      "KUBE_RBAC_PROXY_IMAGE=$KUBE_RBAC_PROXY_IMAGE"
    ;;
  *)
    echo "Usage: $0 <operand/operator name>"
    exit 1
    ;;
esac
