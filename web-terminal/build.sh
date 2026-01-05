#!/bin/bash

source version.sh

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_EXEC="${REGISTRY}/exec:${OCP_DATE}"
IMG_TOOLING="${REGISTRY}/tooling:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/bundle:${OCP_DATE}"

submodule_initialize operator wto-${OCP_SHORT}
submodule_initialize exec main
submodule_initialize tooling main

podman build -t "${IMG_OPERATOR}" -f operator/build/dockerfiles/controller.Dockerfile operator
podman build -t "${IMG_EXEC}" -f exec/build/Dockerfile exec

pushd tooling
source ./etc/get-tooling-versions.sh
./get-sources.sh
podman build -t "${IMG_TOOLING}" -f Dockerfile .
popd

push_all_images

# Build operator bundle image

convert_all_images_to_digest

pushd operator

yq e -i ".metadata.annotations.containerImage = \"${IMG_OPERATOR}\" |
  .spec.install.spec.deployments[0].spec.template.spec.containers[0].image = \"${IMG_OPERATOR}\" |
  .spec.install.spec.deployments[0].spec.template.spec.containers[0].env |=
    map(select(.name == \"RELATED_IMAGE_web_terminal_exec\").value = \"${IMG_EXEC}\") |
  .spec.install.spec.deployments[0].spec.template.spec.containers[0].env |=
    map(select(.name == \"RELATED_IMAGE_web_terminal_tooling\").value = \"${IMG_TOOLING}\") |
  .metadata.name = \"web-terminal.v${OCP_DATE}\" |
  .spec.version = \"${OCP_DATE}\" |
  del(.spec.replaces)" \
  ./manifests/web-terminal.clusterserviceversion.yaml

# Fix the bundle annotation labels
yq e -i ".annotations *= {
  \"operators.operatorframework.io.bundle.channel.default.v1\": \"alpha\",
  \"operators.operatorframework.io.bundle.channels.v1\": \"alpha\"
}" ./metadata/annotations.yaml

podman build --label "operators.operatorframework.io.bundle.channels.v1=${CHANNEL}" \
             --label "operators.operatorframework.io.bundle.channel.default.v1=${DEFAULT_CHANNEL}" \
             -f build/dockerfiles/Dockerfile -t "${IMG_BUNDLE}" .
podman push "${IMG_BUNDLE}"

popd

submodule_reset operator wto-${OCP_SHORT}
submodule_reset exec main
submodule_reset tooling main