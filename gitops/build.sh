#!/bin/bash

MAJOR=1
MINOR=16

source ../common.sh

REGISTRY="${BASE_REGISTRY}/gitops"

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_ARGOCD="${REGISTRY}/argocd:${OCP_DATE}"
IMG_CLI="${REGISTRY}/cli:${OCP_DATE}"
IMG_DEX="${REGISTRY}/dex:${OCP_DATE}"
IMG_EXTENSIONS="${REGISTRY}/extensions:${OCP_DATE}"
IMG_ROLLOUTS="${REGISTRY}/rollouts:${OCP_DATE}"
IMG_CONSOLE_PLUGIN="${REGISTRY}/console-plugin:${OCP_DATE}"
IMG_BACKEND="${REGISTRY}/backend:${OCP_DATE}"
IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"


submodule_initialize argo-cd main
submodule_initialize argo-rollouts main
submodule_initialize argocd-extension-installer
submodule_initialize backend master
submodule_initialize console-plugin main
submodule_initialize dex main
submodule_initialize must-gather main
submodule_initialize operator v${OCP_SHORT}
submodule_initialize rollout-extension


# Build the images
podman build -f operator/Containerfile.plugin -t ${IMG_OPERATOR} operator
podman build -f argo-cd/Containerfile.plugin -t ${IMG_ARGOCD} \
--build-arg ARGO_CD_VERSION=$(git -C argo-cd/argo-cd describe --tags) \
--build-arg ARGO_CD_COMMIT=$(git -C argo-cd/argo-cd rev-parse HEAD) \
--build-arg KUSTOMIZE_VERSION=$(git -C argo-cd/kustomize describe --tags --exact-match | sed 's/^kustomize\///') \
--build-arg HELM_VERSION=$(git -C argo-cd/helm describe --tags --exact-match) \
--build-arg HELM_COMMIT=$(git -C argo-cd/helm rev-parse HEAD) \
--build-arg GIT_LFS_VERSION=$(git -C argo-cd/git-lfs describe --tags) \
argo-cd
podman build -f argo-cd/Containerfile.cli.plugin -t ${IMG_CLI} argo-cd
podman build -f dex/Containerfile.plugin -t ${IMG_DEX} --build-arg VERSION=$(git -C dex describe --tags --always --abbrev=7) dex
podman build -f argocd-extensions.Containerfile -t ${IMG_EXTENSIONS} ../
podman build -f argo-rollouts/Containerfile.rollouts.plugin -t ${IMG_ROLLOUTS} \
--build-arg ROLLOUTS_VERSION=$(git -C argo-rollouts/argo-rollouts describe --tag --exact-match) \
--build-arg ROLLOUTS_COMMIT=$(git -C argo-rollouts/argo-rollouts rev-parse HEAD) \
argo-rollouts
podman build -f backend/.konflux/Containerfile.plugin -t ${IMG_BACKEND} \
--build-arg GIT_COMMIT=$(git -C gitops-backend rev-parse HEAD) backend
podman build -f console-plugin/.konflux/Containerfile.plugin -t ${IMG_CONSOLE_PLUGIN} console-plugin
podman build --from "$(get_payload_component "must-gather")" -f must-gather/.konflux/Containerfile.plugin -t ${IMG_MUST_GATHER} must-gather

# Push the images
podman push ${IMG_ARGOCD}
podman push ${IMG_CLI}
podman push ${IMG_DEX}
podman push ${IMG_EXTENSIONS}
podman push ${IMG_ROLLOUTS}
podman push ${IMG_BACKEND}
podman push ${IMG_CONSOLE_PLUGIN}
podman push ${IMG_OPERATOR}
podman push ${IMG_MUST_GATHER}

export ARGOCD_DEX_IMAGE="${IMG_DEX}"
export ARGOCD_KEYCLOAK_IMAGE="quay.io/keycloak/keycloak:26.2"
export BACKEND_IMAGE="${IMG_BACKEND}"
export ARGOCD_IMAGE="${IMG_ARGOCD}"
export ARGOCD_REPOSERVER_IMAGE="${IMG_ARGOCD}"
export ARGOCD_REDIS_IMAGE="quay.io/sclorg/redis-7-c9s:latest"
export ARGOCD_REDIS_HA_PROXY_IMAGE="$(get_payload_component 'haproxy-router')"
export KUBE_RBAC_PROXY_IMAGE="$(get_payload_component 'kube-rbac-proxy')"
export GITOPS_CONSOLE_PLUGIN_IMAGE="${IMG_CONSOLE_PLUGIN}"
export ARGOCD_EXTENSION_IMAGE="${IMG_EXTENSIONS}"
export ARGO_ROLLOUTS_IMAGE="${IMG_ROLLOUTS}"
export MUST_GATHER_IMAGE="${IMG_MUST_GATHER}"

# Envsubst env-override.yaml
export ENV_OVERRIDES="$(envsubst < env-override.yaml)"

# Build the operator bundle
pushd operator
# Inject ENV_VARS YAML into manager.yaml
yq e -i 'select(.kind == "Deployment").spec.template.spec.containers[0].env = env(ENV_OVERRIDES)' config/manager/manager.yaml
yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\"" config/manifests/bases/gitops-operator.clusterserviceversion.yaml
yq e -i '.spec.template.spec.containers[0].image = env(KUBE_RBAC_PROXY_IMAGE)' config/default/manager_auth_proxy_patch.yaml

echo "$OPERATOR_SDK"
make bundle IMG=${IMG_OPERATOR} \
  "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
  BUNDLE_IMG=${IMG_BUNDLE} \
  VERSION="${OCP_DATE}"

# Build and push the bundle image
podman build -f bundle.Dockerfile -t ${IMG_BUNDLE} .
podman push ${IMG_BUNDLE}

popd

# Reset submodules
reset_submodule argo-cd
reset_submodule argo-rollouts
reset_submodule argocd-extension-installer
reset_submodule backend
reset_submodule console-plugin
reset_submodule dex
reset_submodule must-gather
reset_submodule operator
reset_submodule rollout-extension