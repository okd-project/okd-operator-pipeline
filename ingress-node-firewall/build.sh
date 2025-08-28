#!/bin/bash

NAMESPACE="ingress-node-firewall"

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_DAEMON="${REGISTRY}/daemon:${OCP_DATE}"
export IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

submodule_initialize operator release-${OCP_SHORT}

podman build -t $IMG_OPERATOR -f operator.Containerfile ../
podman build -t $IMG_DAEMON -f daemon.Containerfile ../

push_all_images

pushd operator

yq e -i ".metadata.annotations.containerImage = env(IMG_OPERATOR)" ./config/manifests/bases/ingress-node-firewall.clusterserviceversion.yaml
yq e -i "with(.spec.template.spec.containers[0] ;
  .env |= map(select(.name == \"DAEMONSET_IMAGE\").value = env(IMG_DAEMON)) |
  .env |= map(select(.name == \"KUBE_RBAC_PROXY_IMAGE\").value = env(IMG_KUBE_RBAC_PROXY))
)" ./config/manager/env.yaml
yq e -i "with(.spec.template.spec ;
  .containers[] | select(.name == \"kube-rbac-proxy\").image = env(IMG_KUBE_RBAC_PROXY)
)" ./config/manager/manager.yaml

make bundle VERSION=${OCP_DATE} CSV_VERSION=${OCP_DATE} IMG=${IMG_OPERATOR} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
 BUNDLE_IMG=${IMG_BUNDLE} NAMESPACE=openshift-ingress-node-firewall DAEMON_IMG=${IMG_DAEMON}

podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
podman push $IMG_BUNDLE

popd

submodule_reset operator release-${OCP_SHORT}