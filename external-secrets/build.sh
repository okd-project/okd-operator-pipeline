#!/bin/bash

NAMESPACE="external-secrets"

MAJOR=1
MINOR=0

ES_RELEASE="0.19"
BITWARDEN_SDK_RELEASE="0.5.1"

source ../common.sh

ES_VERSION="${ES_RELEASE}.0-${DATE}"
BITWARDEN_SDK_VERSION="${BITWARDEN_SDK_RELEASE}-${DATE}"

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_EXTERNAL_SECRETS="${REGISTRY}/external-secrets:${ES_VERSION}"
export IMG_BITWARDEN_SDK="${REGISTRY}/bitwarden-sdk-server:${BITWARDEN_SDK_VERSION}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

submodule_initialize operator release-${OCP_SHORT}
submodule_initialize external-secrets release-${ES_RELEASE}
submodule_initialize bitwarden-sdk-server.Containerfile release-${BITWARDEN_SDK_RELEASE}

podman build -t $IMG_OPERATOR -f operator.Containerfile .
podman build -t $IMG_EXTERNAL_SECRETS -f external-secrets.Containerfile .
podman build -t $IMG_BITWARDEN_SDK -f bitwarden-sdk-server.Containerfile .

push_all_images

pushd operator

function edit_manager_env() {
  local env_name=$1
  local env_value=$2
  # Replace value of env variable in manager/env.yaml found at .spec.template.spec.containers[0].env
  yq e -i "with(select(.kind == \"Deployment\") | .spec.template.spec.containers[0] ;
    .env |= map(select(.name == \"${env_name}\").value = \""${env_value}"\")
  )" ./config/manager/manager.yaml
}

yq e -i ".metadata.annotations.containerImage = env(IMG_OPERATOR)" ./config/manifests/bases/external-secrets-operator.clusterserviceversion.yaml
edit_manager_env "OPERATOR_IMAGE_VERSION" "${OCP_DATE}"
edit_manager_env "RELATED_IMAGE_EXTERNAL_SECRETS" "${IMG_EXTERNAL_SECRETS}"
edit_manager_env "OPERAND_EXTERNAL_SECRETS_IMAGE_VERSION" "${ES_VERSION}"
edit_manager_env "RELATED_IMAGE_BITWARDEN_SDK_SERVER" "${IMG_BITWARDEN_SDK}"
edit_manager_env "BITWARDEN_SDK_SERVER_IMAGE_VERSION" "${BITWARDEN_SDK_VERSION}"

make bundle VERSION=${OCP_DATE} CSV_VERSION=${OCP_DATE} IMG=${IMG_OPERATOR} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
 BUNDLE_IMG=${IMG_BUNDLE}

podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
podman push $IMG_BUNDLE

popd

submodule_reset operator release-${OCP_SHORT}
submodule_reset external-secrets release-${ES_RELEASE}
submodule_reset bitwarden-sdk-server release-${BITWARDEN_SDK_RELEASE}