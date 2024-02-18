#!/bin/bash

BASE_IMAGE_REGISTRY=quay.io/okderators

case $1 in
  "bundle-tools")
    tkn pipeline start operand \
      --param repo-url=https://github.com/upstream-operators/okd-operator-pipeline \
      --param repo-ref=main \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=bundle-tools \
      --param image-version=dev \
      --workspace name=workspace,claimName=bundle-tools-volume \
      --workspace name=patches,config=bundle-tools-patch \
      --pod-template pod-template.yaml \
      -n okd-team
  "gitops-console-plugin")
    tkn pipeline start operand \
      --param repo-url=https://github.com/redhat-developer/gitops-console-plugin \
      --param repo-ref=main \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=gitops-console-plugin \
      --param image-version=dev \
      --workspace name=workspace,claimName=gitops-console-plugin-volume \
      --workspace name=patches,config=gitops-console-plugin-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  "gitops-backend")
    tkn pipeline start operand-golang \
      --param repo-url=https://github.com/redhat-developer/gitops-backend \
      --param repo-ref=master \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=gitops-backend \
      --param image-version=dev \
      --workspace name=workspace,claimName=gitops-backend-volume \
      --workspace name=patches,config=gitops-backend-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  "gitops-operator")
    tkn pipeline start operator-golang \
      --param repo-url=https://github.com/redhat-developer/gitops-operator \
      --param repo-ref=master \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=gitops-operator \
      --param image-version=dev \
      --workspace name=workspace,claimName=gitops-operator-volume \
      --workspace name=patches,config=gitops-operator-patch \
      --pod-template pod-template.yaml \
      -n okd-team
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
    tkn pipeline start operator-golang \
      --param repo-url=https://github.com/noobaa/noobaa-operator \
      --param repo-ref=master \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=noobaa-operator \
      --param image-version=dev \
      --workspace name=workspace,claimName=noobaa-operator-volume \
      --workspace name=patches,config=noobaa-operator-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  "logging-view-plugin")
    tkn pipeline start operand \
      --param repo-url=https://github.com/openshift/logging-view-plugin \
      --param repo-ref=main \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=logging-view-plugin \
      --param image-version=dev \
      --workspace name=workspace,claimName=logging-view-plugin-volume \
      --workspace name=patches,config=logging-view-plugin-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  "log-file-metric-exporter")
    tkn pipeline start operand \
      --param repo-url=https://github.com/ViaQ/log-file-metric-exporter \
      --param repo-ref=release-5.8 \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=log-file-metric-exporter \
      --param image-version=dev \
      --workspace name=workspace,claimName=log-file-metric-exporter-volume \
      --workspace name=patches,config=log-file-metric-exporter-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  *)
    echo "Usage: $0 <gitops-console-plugin|gitops-backend|gitops-operator>"
    exit 1
    ;;
esac
