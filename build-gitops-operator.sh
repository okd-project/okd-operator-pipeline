#!/bin/bash

tkn pipeline start pipeline-dev-all \
  --param repo-url=https://github.com/redhat-developer/gitops-operator \
  --param repo-name=gitops-operator \
  --param repo-branch=master \
  --param base-image-registry=ghcr.io/upstream-operators/images \
  --param bundle-version=1.8.0 \
  --param channel=preview \
  --param default-channel=preview \
  --param catalog-image=ghcr.io/upstream-operators/images/okd-dev-community-operator=0.0.1 \
  --param binary-name=manager \
  --workspace name=shared-workspace,claimName=pipeline-pvc-dev \
  -n okd-team
