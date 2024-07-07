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
  if [ -z "$ENV" ]; then
      ENV_MAP="$4"
    else
      ENV_MAP="$ENV $4"
    fi
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
  "gitops")
    build_operand https://github.com/redhat-developer/gitops-console-plugin "${CONSOLE_REF:-main}" gitops-console-plugin
    build_operand https://github.com/redhat-developer/gitops-backend "${BACKEND_REF:-master}" gitops-backend
    CONSOLE_IMAGE="$BASE_IMAGE_REGISTRY/gitops-console-plugin"
    BACKEND_IMG="$BASE_IMAGE_REGISTRY/gitops-backend:$VERSION"
    build_operator https://github.com/redhat-developer/gitops-operator "${OPERATOR_REF:-v1.12}" gitops-operator \
      "CONSOLE_IMAGE=$CONSOLE_IMAGE CONSOLE_IMAGE_TAG=$VERSION BACKEND_IMG=$BACKEND_IMG"
    ;;
  "cluster-logging")
    build_operator https://github.com/openshift/loki "${BRANCH:-release-5.9}" loki
    build_operand https://github.com/ViaQ/vector "${BRANCH:-release-5.9}" vector
    build_operand https://github.com/ViaQ/logging-fluentd "${BRANCH:-v1.16.x}" fluentd
    build_operand https://github.com/openshift/logging-view-plugin "${BRANCH:-release-5.9}" logging-view-plugin
    FLUENTD="$BASE_IMAGE_REGISTRY/fluentd:$VERSION"
    VECTOR="$BASE_IMAGE_REGISTRY/vector:$VERSION"
    LOG_FILE_METRIC_EXPORTER="$BASE_IMAGE_REGISTRY/log-file-metric-exporter:$VERSION"
    LOGGING_VIEW_PLUGIN="$BASE_IMAGE_REGISTRY/logging-view-plugin:$VERSION"
    build_operator https://github.com/openshift/cluster-logging-operator "${BRANCH:-release-5.9}" cluster-logging-operator \
      "IMAGE_LOGGING_FLUENTD=$FLUENTD IMAGE_LOGGING_VECTOR=$VECTOR IMAGE_LOGFILEMETRICEXPORTER=$LOG_FILE_METRIC_EXPORTER IMAGE_LOGGING_CONSOLE_PLUGIN=$LOGGING_VIEW_PLUGIN"
    ;;
  "local-storage")
    KUBE_RBAC_PROXY_IMAGE=${KUBE_RBAC_PROXY_IMAGE:-quay.io/okderators/kube-rbac-proxy:4.15}
    build_operator https://github.com/openshift/local-storage-operator "${BRANCH:-release-4.15}" local-storage-operator \
      "KUBE_RBAC_PROXY_IMAGE=$KUBE_RBAC_PROXY_IMAGE"
    ;;
  "odf")
    build_operand https://github.com/red-hat-storage/rook "${ROOK_COMMIT:-release-4.15}" rook-ceph
    build_operand https://github.com/red-hat-storage/kubernetes-csi-addons "${CSIADDONS_COMMIT:-release-4.15}" csi-addons
    build_operand https://github.com/red-hat-storage/noobaa-core "${NOOBAA_CORE_COMMIT:-release-4.15}" noobaa-core
    build_operand https://github.com/red-hat-storage/odf-console "${ODF_CONSOLE_COMMIT:-release-4.15}" odf-console

    NOOBAA_CORE_IMG="$BASE_IMAGE_REGISTRY/noobaa-core:$VERSION"
    ROOK_IMG="$BASE_IMAGE_REGISTRY/rook-ceph:$VERSION"
    ROOK_CSIADDONS_IMAGE="$BASE_IMAGE_REGISTRY/csi-k8s-sidecar:$VERSION"
    NOOBAA_DB_IMAGE=${NOOBAA_DB_IMAGE:-quay.io/sclorg/postgresql-15-c9s:latest}
    NOOBAA_PSQL_12_IMAGE=${NOOBAA_PSQL_12_IMAGE:-quay.io/sclorg/postgresql-12-c8s:latest}
    CEPH_IMG=${CEPH_IMG:-quay.io/ceph/ceph:v18.2.2}
    OAUTH_PROXY_IMG=${OAUTH_PROXY_IMG:-quay.io/openshift/origin-oauth-proxy:4.15}
    KUBE_RBAC_PROXY_IMAGE=${KUBE_RBAC_PROXY_IMAGE:-quay.io/okderators/kube-rbac-proxy:4.15}
    ROOK_CSI_PROVISIONER_IMAGE="registry.k8s.io/sig-storage/csi-provisioner:v3.6.4"
    ROOK_CSI_RESIZER_IMAGE="registry.k8s.io/sig-storage/csi-resizer:v1.9.4"
    ROOK_CSI_SNAPSHOTTER_IMAGE="registry.k8s.io/sig-storage/csi-snapshotter:v6.3.4"
    ROOK_CSI_ATTACHER_IMAGE="registry.k8s.io/sig-storage/csi-attacher:v4.4.4"
    ROOK_CSI_REGISTRAR_IMAGE="registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.9.4"
    ROOK_CSI_CEPH_IMAGE="quay.io/cephcsi/cephcsi:v3.10.2"

    SKIP_RANGE=${SKIP_RANGE:-">=4.2.0<$VERSION"}
    REPLACES=${REPLACES:-"null"}
    CSV_NAME=${CSV_NAME:-noobaa-operator.v${VERSION}}
    build_operator https://github.com/red-hat-storage/noobaa-operator "${NOOBAA_OPERATOR_COMMIT:-release-4.15}" noobaa-operator \
      "CORE_IMAGE=$NOOBAA_CORE_IMG DB_IMAGE=$NOOBAA_DB_IMAGE SKIP_RANGE=$SKIP_RANGE REPLACES=$REPLACES\
 CSV_NAME=$CSV_NAME PSQL_12_IMAGE=$NOOBAA_PSQL_12_IMAGE obc-crd=owned"

    build_operator https://github.com/red-hat-storage/ocs-operator "${OCS_COMMIT:-release-4.15}" ocs-operator \
      "NOOBAA_CORE_IMG=$NOOBAA_CORE_IMG NOOBAA_DB_IMG=$NOOBAA_DB_IMAGE ROOK_IMG=$ROOK_IMG CEPH_IMG=$CEPH_IMG\
 OAUTH_PROXY_IMG=$OAUTH_PROXY_IMG ROOK_CSIADDONS_IMAGE=$ROOK_CSIADDONS_IMAGE\
 ROOK_CSI_PROVISIONER_IMAGE=$ROOK_CSI_PROVISIONER_IMAGE ROOK_CSI_RESIZER_IMAGE=$ROOK_CSI_RESIZER_IMAGE\
 ROOK_CSI_SNAPSHOTTER_IMAGE=$ROOK_CSI_SNAPSHOTTER_IMAGE ROOK_CSI_ATTACHER_IMAGE=$ROOK_CSI_ATTACHER_IMAGE\
 ROOK_CSI_REGISTRAR_IMAGE=$ROOK_CSI_REGISTRAR_IMAGE ROOK_CSI_CEPH_IMAGE=$ROOK_CSI_CEPH_IMAGE"

    build_operator https://github.com/red-hat-storage/odf-operator "${ODF_COMMIT:-release-4.15}" odf-operator \
      "IMAGE_REGISTRY=$IMAGE_REGISTRY REGISTRY_NAMESPACE=$REGISTRY_NAMESPACE OCS_BUNDLE_IMG_TAG=$VERSION\
 NOOBAA_BUNDLE_IMG_TAG=$VERSION CSIADDONS_BUNDLE_IMG_NAME=csi-addons-bundle\
 CSIADDONS_BUNDLE_IMG_TAG=$VERSION ODF_CONSOLE_IMG_TAG=$VERSION\
 OPERATOR_CATALOGSOURCE=$CATALOG_SOURCE OPERATOR_CATALOG_NAMESPACE=$CATALOG_NAMESPACE\
 OSE_KUBE_RBAC_PROXY_IMG=$KUBE_RBAC_PROXY_IMAGE"
    ;;
  *)
    echo "Usage: $0 <odf|cluster-logging|gitops|local-storage>"
    exit 1
    ;;
esac
