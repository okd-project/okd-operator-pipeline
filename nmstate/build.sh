#!/bin/bash

source version.sh

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_HANDLER="${REGISTRY}/handler:${OCP_DATE}"
IMG_CONSOLE_PLUGIN="${REGISTRY}/console-plugin:${OCP_DATE}"

IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

IMG_BUNDLE="${REGISTRY}/bundle:${OCP_DATE}"

submodule_initialize operator release-${OCP_SHORT}
submodule_initialize console-plugin release-${OCP_SHORT}

#podman build --build-arg OCP_SHORT=${OCP_SHORT} -t $IMG_OPERATOR -f images/operator.Containerfile operator
#podman build --build-arg OCP_SHORT=${OCP_SHORT} -t $IMG_HANDLER -f images/handler.Containerfile operator
#podman build --build-arg OCP_SHORT=${OCP_SHORT} -t $IMG_CONSOLE_PLUGIN -f images/console-plugin.Containerfile console-plugin

#push_all_images

# Build operator bundle image

convert_all_images_to_digest

pushd operator

yq e -i ".metadata.annotations.support = \"OKD Community\" |
.metadata.annotations.containerImage = env(IMG_OPERATOR) |
.metadata.annotations.categories = \"OKD Optional\" |
.spec.provider.name = \"OKD Community\" |
.spec.maintainers[0].name = \"OKD Community\" |
.spec.maintainers[0].email = \"maintainers@okd.io\"" ./manifests/bases/kubernetes-nmstate-operator.clusterserviceversion.yaml

namespace=openshift-nmstate
export VERSION="${OCP_DATE}"

make ocp-update-bundle-manifests KUBE_RBAC_PROXY_IMAGE=$IMG_KUBE_RBAC_PROXY HANDLER_IMAGE=${IMG_HANDLER} \
 PLUGIN_IMAGE=${IMG_CONSOLE_PLUGIN} OPERATOR_IMAGE=${IMG_OPERATOR} BUNDLE_IMG=${IMG_BUNDLE} \
 "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" MANIFEST_BASES_DIR=manifests/bases MONITORING_NAMESPACE=openshift-monitoring \
 HANDLER_NAMESPACE=$namespace OPERATOR_NAMESPACE=$namespace PLUGIN_NAMESPACE=$namespace

podman build -f manifests/stable/bundle.Dockerfile -t "${IMG_BUNDLE}" .
podman push "${IMG_BUNDLE}"

popd

submodule_reset console-plugin release-${OCP_SHORT}
submodule_reset operator release-${OCP_SHORT}
