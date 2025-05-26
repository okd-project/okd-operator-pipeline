#!/bin/bash

set -e -x

source ../common.sh

REGISTRY="${BASE_REGISTRY}/ingress-node-firewall"

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_DAEMON="${REGISTRY}/daemon:${OCP_DATE}"

IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

apply_patch operator release-${OCP_SHORT}

podman build -t $IMG_OPERATOR -f operator.Containerfile ../
podman build -t $IMG_DAEMON -f daemon.Containerfile ../

podman push $IMG_OPERATOR
podman push $IMG_DAEMON

pushd operator

export DAEMONSET_IMAGE=$IMG_DAEMON
export KUBE_RBAC_PROXY_IMAGE=$IMG_KUBE_RBAC_PROXY
export IMG_OPERATOR=$IMG_OPERATOR

yq e -i ".metadata.annotations.containerImage = env(IMG_OPERATOR)" ./config/manifests/bases/ingress-node-firewall.clusterserviceversion.yaml
yq e -i "with(.spec.template.spec.containers[0] ;
  .env |= map(select(.name == \"DAEMONSET_IMAGE\").value = env(DAEMONSET_IMAGE)) |
  .env |= map(select(.name == \"KUBE_RBAC_PROXY_IMAGE\").value = env(KUBE_RBAC_PROXY_IMAGE))
)" ./config/manager/env.yaml
yq e -i "with(.spec.template.spec ;
  .containers[] | select(.name == \"kube-rbac-proxy\").image = env(KUBE_RBAC_PROXY_IMAGE)
)" ./config/manager/manager.yaml

make bundle VERSION=${OCP_DATE} CSV_VERSION=${OCP_DATE} IMG=$IMG_OPERATOR "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
 BUNDLE_IMG=$IMG_BUNDLE NAMESPACE=openshift-ingress-node-firewall DAEMON_IMG=${IMG_DAEMON}

podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
podman push $IMG_BUNDLE

popd