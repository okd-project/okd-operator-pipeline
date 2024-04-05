#!/bin/bash

NAMESPACE=${NAMESPACE:-okd-team}
BASE_IMAGE_REGISTRY=${BASE_IMAGE_REGISTRY:-quay.io/okderators}
CHANNEL=${CHANNEL:-dev}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL:-stable}
VERSION=${VERSION:-dev}
ENV=${ENV:-""}
BUILD_IMAGE=${BUILD_IMAGE:-quay.io/okderators/bundle-tools:vdev}
ENABLE_TIMESTAMP=${ENABLE_TIMESTAMP:-true}

function build_operand() {
  NAME=$3
  ENV_MAP="$ENV $4"
  tkn pipeline start operand \
    --param repo-url=$1 \
    --param repo-ref=$2 \
    --param base-image-registry=$BASE_IMAGE_REGISTRY \
    --param image-name=$3 \
    --param image-version=$VERSION \
    --param build-image=$BUILD_IMAGE \
    --param env-map="$ENV_MAP" \
    --param enable-timestamp=$ENABLE_TIMESTAMP \
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
    --param build-image=$BUILD_IMAGE \
    --param enable-timestamp=$ENABLE_TIMESTAMP \
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
  "gitops-console-plugin")
    build_operand https://github.com/redhat-developer/gitops-console-plugin "${BRANCH:-main}" gitops-console-plugin
    ;;
  "gitops-backend")
    build_operand https://github.com/redhat-developer/gitops-backend "${BRANCH:-master}" gitops-backend
    ;;
  "gitops-operator")
    build_operator https://github.com/redhat-developer/gitops-operator "${BRANCH:-master}" gitops-operator
    ;;
  "noobaa-core")
    build_operand https://github.com/noobaa/noobaa-core "${BRANCH:-5.15}" noobaa-core
    ;;
  "noobaa-operator")
    NOOBAA_DB_IMAGE=${NOOBAA_DB_IMAGE:-quay.io/sclorg/postgresql-16-c9s:latest}
    NOOBAA_CORE_IMAGE=${NOOBAA_CORE_IMAGE:-quay.io/okderators/noobaa-core:dev}
    SKIP_RANGE=${SKIP_RANGE:-"1.0.0-1.0.0"}
    REPLACES=${REPLACES:-"0.0.0"}
    CSV_NAME=${CSV_NAME:-noobaa-operator.v${VERSION}}
    PSQL_12_IMAGE=${PSQL_12_IMAGE:-quay.io/sclorg/postgresql-12-c9s:latest}
    build_operator https://github.com/noobaa/noobaa-operator "${BRANCH:-5.15}" noobaa-operator \
      "CORE_IMAGE=\"$NOOBAA_CORE_IMAGE\" DB_IMAGE=\"$NOOBAA_DB_IMAGE\" SKIP_RANGE=\"$SKIP_RANGE\" REPLACES=\"$REPLACES\" CSV_NAME=\"$CSV_NAME\" PSQL_12_IMAGE=\"$PSQL_12_IMAGE\""
    ;;
  "logging-view-plugin")
    build_operand https://github.com/openshift/logging-view-plugin "${BRANCH:-main}" logging-view-plugin
    ;;
  "log-file-metric-exporter")
    build_operand https://github.com/ViaQ/log-file-metric-exporter "${BRANCH:-release-5.8}" log-file-metric-exporter
    ;;
  "ocs-operator")
    NOOBAA_DB_IMAGE=${NOOBAA_DB_IMAGE:-quay.io/sclorg/postgresql-16-c9s:latest}
    NOOBAA_CORE_IMAGE=${NOOBAA_CORE_IMAGE:-quay.io/okderators/noobaa-core:dev}
    ROOK_IMAGE=${ROOK_IMAGE:-quay.io/okderators/rook-ceph:dev}
    CEPH_IMAGE=${CEPH_IMAGE:-quay.io/ceph/ceph:v18.2.1}
    NOOBAA_BUNDLE_FULL_IMAGE_NAME=${NOOBAA_BUNDLE_FULL_IMAGE_NAME:-quay.io/okderators/noobaa-operator-bundle:dev}
    OCS_IMAGE=${OCS_IMAGE:-quay.io/okderators/ocs-operator:dev}
    OCS_METRICS_EXPORTER_IMAGE=${OCS_METRICS_EXPORTER_IMAGE:-quay.io/okderators/ocs-metrics-exporter:dev}
    UX_BACKEND_OAUTH_IMAGE=${UX_BACKEND_OAUTH_IMAGE:-quay.io/openshift/origin-oauth-proxy:latest}
    build_operator https://github.com/red-hat-storage/ocs-operator "${BRANCH:-release-4.15}" ocs-operator \
      "CSV_VERSION=999.999.999 NOOBAA_CORE_IMAGE=$NOOBAA_CORE_IMAGE NOOBAA_DB_IMAGE=$NOOBAA_DB_IMAGE ROOK_IMAGE=$ROOK_IMAGE CEPH_IMAGE=$CEPH_IMAGE NOOBAA_BUNDLE_FULL_IMAGE_NAME=$NOOBAA_BUNDLE_FULL_IMAGE_NAME OCS_IMAGE=$OCS_IMAGE OCS_METRICS_EXPORTER_IMAGE=$OCS_METRICS_EXPORTER_IMAGE UX_BACKEND_OAUTH_IMAGE=$UX_BACKEND_OAUTH_IMAGE"
    ;;
  "ocs-metrics-exporter")
    build_operand https://github.com/red-hat-storage/ocs-operator "${BRANCH:-release-4.15}" ocs-metrics-exporter
    ;;
  "odf-console")
    build_operand https://github.com/red-hat-storage/odf-console "${BRANCH:-release-4.15}" odf-console
    ;;
  "odf-operator")
    build_operator https://github.com/red-hat-storage/odf-operator "${BRANCH:-main}" odf-operator
    ;;
  "rook-ceph")
    build_operand https://github.com/red-hat-storage/rook "${BRANCH:-master}" rook-ceph
    ;;
  *)
    echo "Usage: $0 <operand/operator name>"
    exit 1
    ;;
esac
