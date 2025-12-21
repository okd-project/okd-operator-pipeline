#!/bin/bash

NAMESPACE="pf-status-relay"

DATE="2025-12-14-152353"

source ../common.sh

IMG_OPERATOR=${REGISTRY}/operator:${OCP_DATE}
IMG_RELAY=${REGISTRY}/relay:${OCP_DATE}
IMG_BUNDLE=${REGISTRY}/bundle:${OCP_DATE}
IMG_KUBE_RBAC_PROXY=$(get_payload_component "kube-rbac-proxy")

submodule_initialize operator release-${OCP_SHORT}
submodule_initialize relay release-${OCP_SHORT}

#podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_OPERATOR -f operator.Containerfile operator
#podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_RELAY -f relay.Containerfile relay
#
#push_all_images

convert_all_images_to_digest

pushd operator

yq e -i ".spec.template.spec.containers[0].image = \"${IMG_KUBE_RBAC_PROXY}\"" config/default/manager_auth_proxy_patch.yaml
yq e -i ".spec.template.spec.containers[0].env[0].value = \"${IMG_RELAY}\"" config/manager/env_patch.yaml

make bundle VERSION=${OCP_DATE} IMG=${IMG_OPERATOR} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" BUNDLE_IMG=${IMG_BUNDLE} RELAY_IMG=${IMG_RELAY}

podman build -f bundle.Dockerfile -t ${IMG_BUNDLE} .
podman push ${IMG_BUNDLE}

popd

submodule_reset operator release-${OCP_SHORT}
submodule_reset relay release-${OCP_SHORT}