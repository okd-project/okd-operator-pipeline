#!/bin/bash

DATE="2026-02-07-151505"

source version.sh
source ../common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_ARGOCD="${REGISTRY}/argocd:${OCP_DATE}"
export IMG_CLI="${REGISTRY}/cli:${OCP_DATE}"
export IMG_AGENTCTL="${REGISTRY}/agentctl:${OCP_DATE}"
export IMG_AGENT="${REGISTRY}/agent:${OCP_DATE}"
export IMG_IMAGE_UPDATER="${REGISTRY}/image-updater:${OCP_DATE}"
export IMG_DEX="${REGISTRY}/dex:${OCP_DATE}"
export IMG_EXTENSIONS="${REGISTRY}/extensions:${OCP_DATE}"
export IMG_ROLLOUTS="${REGISTRY}/rollouts:${OCP_DATE}"
export IMG_CONSOLE_PLUGIN="${REGISTRY}/console-plugin:${OCP_DATE}"
export IMG_BACKEND="${REGISTRY}/backend:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

export IMG_KUBE_RBAC_PROXY=$(get_payload_component kube-rbac-proxy)
export IMG_HAPROXY_ROUTER=$(get_payload_component haproxy-router)
export IMG_REDIS="quay.io/sclorg/redis-7-c9s:latest"

submodule_initialize release release-${OCP_SHORT}

pushd release

# Versions
CI_ARGO_CD_VERSION="$(git -C sources/argo-cd describe --tags --exact-match 2>/dev/null || true)"
CI_ARGO_CD_COMMIT="$(git -C sources/argo-cd rev-parse HEAD)"
CI_ARGO_ROLLOUTS_VERSION="$(git -C sources/argo-rollouts describe --tags --exact-match 2>/dev/null || true)"
CI_ARGO_ROLLOUTS_COMMIT="$(git -C sources/argo-rollouts rev-parse HEAD)"
CI_GIT_LFS_COMMIT="$(git -C sources/git-lfs rev-parse HEAD)"
CI_KUSTOMIZE_VERSION="$(git -C sources/kustomize describe --tags --exact-match 2>/dev/null || true)"
CI_HELM_VERSION="$(git -C sources/helm describe --tags --exact-match 2>/dev/null || true)"
CI_HELM_COMMIT="$(git -C sources/helm rev-parse HEAD)"
CI_ARGOCD_IMAGE_UPDATER_VERSION="$(git -C sources/argocd-image-updater describe --tags --exact-match 2>/dev/null || true)"
CI_ARGOCD_IMAGE_UPDATER_COMMIT="$(git -C sources/argocd-image-updater rev-parse HEAD)"
CI_DEX_VERSION="$(git -C sources/dex describe --tags --exact-match 2>/dev/null || true)"
CI_DEX_COMMIT="$(git -C sources/dex rev-parse HEAD)"
CI_GITOPS_BACKEND_COMMIT="$(git -C sources/gitops-backend rev-parse HEAD)"

# CLI images
#podman build -t "${IMG_CLI}" -f clis/argocd/Dockerfile \
#  --build-arg CI_ARGO_CD_VERSION="${CI_ARGO_CD_VERSION}" --build-arg CI_ARGO_CD_COMMIT="${CI_ARGO_CD_COMMIT}" \
#  --build-arg CI_VERSION="${OCP_DATE}" .
#podman build -t "${IMG_AGENTCTL}" -f clis/argocd-agentctl/Dockerfile .


# Build the images
#podman build -t "${IMG_ROLLOUTS}" -f containers/argo-rollouts/Dockerfile \
#  --build-arg CI_ARGO_ROLLOUTS_VERSION="${CI_ARGO_ROLLOUTS_VERSION}" \
#  --build-arg CI_ARGO_ROLLOUTS_COMMIT="${CI_ARGO_ROLLOUTS_COMMIT}" --build-arg CI_GIT_LFS_COMMIT="${CI_GIT_LFS_COMMIT}" .
#podman build -t ${IMG_AGENT} -f containers/argocd-agent/Dockerfile .
#podman build -t ${IMG_EXTENSIONS} -f containers/argocd-extensions/Dockerfile .
#podman build -t ${IMG_IMAGE_UPDATER} -f containers/argocd-image-updater/Dockerfile \
#  --build-arg CI_ARGOCD_IMAGE_UPDATER_VERSION="${CI_ARGOCD_IMAGE_UPDATER_VERSION}" \
#  --build-arg CI_ARGOCD_IMAGE_UPDATER_COMMIT="${CI_ARGOCD_IMAGE_UPDATER_COMMIT}" .
#podman build -t ${IMG_ARGOCD} -f containers/argocd-rhel9/Dockerfile \
#  --build-arg CI_ARGO_CD_VERSION="${CI_ARGO_CD_VERSION}" --build-arg CI_ARGO_CD_COMMIT="${CI_ARGO_CD_COMMIT}" \
#  --build-arg CI_GIT_LFS_COMMIT="${CI_GIT_LFS_COMMIT}" --build-arg ARGO_VERSION="${CI_ARGO_CD_VERSION}" \
#  --build-arg CI_VERSION="${OCP_DATE}" --build-arg BUILD_ALL_CLIS=false \
#  --build-arg CI_KUSTOMIZE_VERSION="${CI_KUSTOMIZE_VERSION}" --build-arg CI_HELM_VERSION="${CI_HELM_VERSION}" \
#  --build-arg CI_HELM_COMMIT="${CI_HELM_COMMIT}" --build-arg CI_GIT_LFS_COMMIT="${CI_GIT_LFS_COMMIT}" .
#podman build -t ${IMG_CONSOLE_PLUGIN} -f containers/console-plugin/Dockerfile .
#podman build -t ${IMG_DEX} -f containers/dex/Dockerfile \
#  --build-arg CI_DEX_VERSION="${CI_DEX_VERSION}" --build-arg CI_DEX_COMMIT="${CI_DEX_COMMIT}" .
#podman build -t ${IMG_BACKEND} -f containers/gitops/Dockerfile \
#  --build-arg CI_GITOPS_BACKEND_COMMIT="${CI_GITOPS_BACKEND_COMMIT}" .
#podman build -t ${IMG_OPERATOR} -f containers/gitops-operator/Dockerfile .
#podman build -t ${IMG_MUST_GATHER} --from "$(get_payload_component "must-gather")" -f containers/must-gather/Dockerfile .

# Push the images
#podman push ${IMG_CLI}
#podman push ${IMG_AGENTCTL}
#podman push ${IMG_ROLLOUTS}
#podman push ${IMG_AGENT}
#podman push ${IMG_EXTENSIONS}
#podman push ${IMG_IMAGE_UPDATER}
#podman push ${IMG_ARGOCD}
#podman push ${IMG_CONSOLE_PLUGIN}
#podman push ${IMG_DEX}
#podman push ${IMG_BACKEND}
#podman push ${IMG_OPERATOR}
#podman push ${IMG_MUST_GATHER}

# Envsubst env-override.yaml
export ENV_OVERRIDES="$(envsubst < $DIR/env-override.yaml)"

# Build the operator bundle
pushd sources/gitops-operator

# Replace branding with sed
sed -i 's/Red Hat OpenShift/OKD/g' config/manifests/patches/description.yaml
sed -i 's/OpenShift/OKD/g' config/manifests/patches/description.yaml
# Patch CSV
yq ". *= load(\"$DIR/gitops-operator.clusterserviceversion.yaml\")" config/manifests/bases/gitops-operator.clusterserviceversion.yaml > tmp.yaml
mv tmp.yaml config/manifests/bases/gitops-operator.clusterserviceversion.yaml
# Replace icon
export ICON="$(base64 -w 0 $DIR/../icon.png)"
yq e -i '.[0].value[0].base64data = env(ICON)' config/manifests/patches/icon.yaml

# Inject ENV_VARS YAML into manager.yaml
yq e -i 'select(.kind == "Deployment").spec.template.spec.containers[0].env += env(ENV_OVERRIDES)' config/manager/manager.yaml
yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\"" config/manifests/bases/gitops-operator.clusterserviceversion.yaml
yq e -i '.spec.template.spec.containers[0].image = env(IMG_KUBE_RBAC_PROXY)' config/default/manager_auth_proxy_patch.yaml

make bundle IMG=${IMG_OPERATOR} \
  "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
  BUNDLE_IMG=${IMG_BUNDLE} \
  VERSION="${OCP_DATE}" \
  IMG=${IMG_OPERATOR}

# Build and push the bundle image
podman build -f bundle.Dockerfile -t ${IMG_BUNDLE} .
podman push ${IMG_BUNDLE}

popd
popd

# Reset submodules
submodule_reset release release-${OCP_SHORT}
