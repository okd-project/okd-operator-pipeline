#!/bin/bash

# Configuration and variable setup
NAMESPACE="web-terminal"
MAJOR=1
MINOR=15

source ../common.sh

# Image definitions
export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_EXEC="${REGISTRY}/exec:${OCP_DATE}"
IMG_TOOLING="${REGISTRY}/tooling:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/bundle:${OCP_DATE}"

## Functions

init() {
    submodule_initialize operator wto-${OCP_SHORT}
    submodule_initialize exec main
    submodule_initialize tooling main
}

deinit() {
    submodule_reset operator wto-${OCP_SHORT}
    submodule_reset exec main
    submodule_reset tooling main
}

update() {
    submodule_update operator wto-${OCP_SHORT} https://github.com/redhat-developer/web-terminal-operator.git
    submodule_update tooling main https://github.com/redhat-developer/web-terminal-tooling.git
    submodule_update exec main https://github.com/redhat-developer/web-terminal-exec.git
}

build_containers() {
    podman build -t "${IMG_OPERATOR}" -f operator/build/dockerfiles/controller.Dockerfile operator
    podman build -t "${IMG_EXEC}" -f exec/build/Dockerfile exec

    pushd tooling
    source ./etc/get-tooling-versions.sh
    ./get-sources.sh
    podman build -t "${IMG_TOOLING}" -f Dockerfile .
    popd
}

push_containers() {
    push_all_images
}

build_bundle() {
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
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
