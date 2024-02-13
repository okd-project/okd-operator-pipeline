#!/bin/bash

BASE_IMAGE_REGISTRY=quay.io/okderators

case $1 in
  "gitops-console-plugin")
    tkn pipeline start operand-yarn \
      --param repo-url=https://github.com/redhat-developer/gitops-console-plugin \
      --param repo-ref=main \
      --param base-image-registry=$BASE_IMAGE_REGISTRY \
      --param image-name=gitops-console-plugin \
      --param image-version=0.1.0 \
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
      --param image-version=0.0.1 \
      --param build-context=./cmd/backend-http \
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
      --param csv-location=deploy/olm/noobaa-operator.clusterserviceversion.yaml \
      --workspace name=workspace,claimName=noobaa-operator-volume \
      --workspace name=patches,config=noobaa-operator-patch \
      --pod-template pod-template.yaml \
      -n okd-team
    ;;
  *)
    echo "Usage: $0 <gitops-console-plugin|gitops-backend|gitops-operator>"
    exit 1
    ;;
esac
