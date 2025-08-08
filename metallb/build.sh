#!/bin/bash

NAMESPACE="metallb"

source ../common.sh

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_METALLB="${REGISTRY}/metallb:${OCP_DATE}"
IMG_FRR="${REGISTRY}/frr:${OCP_DATE}"

IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

apply_patch operator release-${OCP_SHORT}

# Build the images
podman build -t "${IMG_OPERATOR}" -f operator.Containerfile ./operator
podman build -t "${IMG_METALLB}" -f metallb.Containerfile ../
podman build -t "${IMG_FRR}" -f frr.Containerfile ../

# Push the images
podman push "${IMG_OPERATOR}"
podman push "${IMG_METALLB}"
podman push "${IMG_FRR}"

pushd operator

yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\"" manifests/ocpcsv/bases/metallb-operator.clusterserviceversion.yaml
yq e -i ".spec.template.spec.containers[0].image = \"${IMG_METALLB}\"" manifests/ocpcsv/controller-webhook-patch.yaml
yq e -i "with(.spec.template.spec.containers[0] ;
  .env |= map(select(.name == \"SPEAKER_IMAGE\").value = \"${IMG_METALLB}\") |
  .env |= map(select(.name == \"CONTROLLER_IMAGE\").value = \"${IMG_METALLB}\") |
  .env |= map(select(.name == \"FRR_IMAGE\").value = \"${IMG_FRR}\") |
  .env |= map(select(.name == \"KUBE_RBAC_PROXY_IMAGE\").value = \"${IMG_KUBE_RBAC_PROXY}\") |
  .env |= map(select(.name == \"FRRK8S_IMAGE\").value = \"${IMG_FRR}\") |
  .image = \"${IMG_OPERATOR}\"
)" manifests/ocpcsv/ocpvariables.yaml

# we need to save and restore as operatorsdk works with the local bundle.Dockerfile
mv bundle.Dockerfile bundle.Dockerfile_orig
rm -rf _cache/ocpmanifests

export OPERATOR_SDK=_cache/operator-sdk
make operator-sdk
export KUSTOMIZE=_cache/kustomize
make kustomize
make manifests

$OPERATOR_SDK generate kustomize manifests --interactive=false -q
$KUSTOMIZE build manifests/ocpcsv | $OPERATOR_SDK generate bundle --output-dir _cache/ocpmanifests -q --overwrite --version $OCP_DATE --extra-service-accounts "controller,speaker"
$OPERATOR_SDK bundle validate _cache/ocpmanifests/

sed -i 's/LABEL com.redhat.openshift.versions=.*$/LABEL com.redhat.openshift.versions="v'"$OCP_SHORT"'"/g' bundle.Dockerfile

podman build -t "${IMG_BUNDLE}" -f bundle.Dockerfile .
podman push "${IMG_BUNDLE}"
popd
