#!/bin/bash

NAMESPACE=${NAMESPACE:-okd-team}
BASE_IMAGE_REGISTRY=${BASE_IMAGE_REGISTRY:-quay.io/okderators}
CHANNEL=${CHANNEL:-dev}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL:-stable}
VERSION=${VERSION:-dev}
ENV_MAP=${ENV_MAP:-""}
BUILD_IMAGE=${BUILD_IMAGE:-quay.io/okderators/bundle-tools:vdev}
ENABLE_TIMESTAMP=${ENABLE_TIMESTAMP:-true}

function build_operand() {
  NAME=$3
  tkn pipeline start operand \
    --param repo-url=$1 \
    --param repo-ref=$2 \
    --param base-image-registry=$BASE_IMAGE_REGISTRY \
    --param image-name=$3 \
    --param image-version=$VERSION \
    --param build-image $BUILD_IMAGE \
    --param enable-timestamp=$ENABLE_TIMESTAMP \
    --param env-map=$ENV_MAP \
    --workspace name=workspace,claimName=$NAME-volume \
    --workspace name=patches,config=$5-patch \
    --pod-template pod-template.yaml \
    -n $NAMESPACE
}

function build_operator() {
  NAME=$3
  tkn pipeline start operator \
    --param repo-url=$1 \
    --param repo-ref=$2 \
    --param base-image-registry=$BASE_IMAGE_REGISTRY \
    --param image-name=$3 \
    --param image-version=$VERSION \
    --param channel=$CHANNEL \
    --param default-channel=$DEFAULT_CHANNEL \
    --param build-image $BUILD_IMAGE \
    --param enable-timestamp=$ENABLE_TIMESTAMP \
    --param env-map=$ENV_MAP \
    --workspace name=workspace,claimName=$NAME-volume \
    --workspace name=patches,config=$NAME-patch \
    --pod-template pod-template.yaml \
    -n $NAMESPACE
}

case $1 in
  "bundle-tools")
    tkn pipeline start image-build \
      --param repo-url=https://github.com/okd-project/okd-operator-pipeline \
      --param repo-ref=ocs \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=bundle-tools \
      --param image-version=dev \
      --workspace name=workspace,claimName=bundle-tools-volume \
      --workspace name=patches,config=bundle-tools-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  "gitops-console-plugin")
    build_operand https://github.com/redhat-developer/gitops-console-plugin main gitops-console-plugin
    ;;
  "gitops-backend")
    build_operand https://github.com/redhat-developer/gitops-backend master gitops-backend
    ;;
  "gitops-operator")
    build_operator https://github.com/redhat-developer/gitops-operator master gitops-operator
    ;;
  "noobaa-core")
    tkn pipeline start operand-noobaa \
      --param repo-url=https://github.com/noobaa/noobaa-core \
      --param repo-ref=master \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=noobaa-core \
      --param image-version=dev \
      --workspace name=workspace,claimName=noobaa-core-volume \
      --workspace name=patches,config=noobaa-core-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  "noobaa-operator")
    build_operator https://github.com/noobaa/noobaa-operator master noobaa-operator
    ;;
  "logging-view-plugin")
    build_operand https://github.com/openshift/logging-view-plugin main logging-view-plugin
    ;;
  "log-file-metric-exporter")
    build_operand https://github.com/ViaQ/log-file-metric-exporter release-5.8 log-file-metric-exporter
    ;;
  "ocs-operator")
    build_operator https://github.com/red-hat-storage/ocs-operator main ocs-operator
    ;;
  *)
    echo "Usage: $0 <operand/operator name>"
    exit 1
    ;;
esac
