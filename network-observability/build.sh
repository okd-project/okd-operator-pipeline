#!/bin/bash

# Configuration and variable setup
NAMESPACE="network-observability"
MAJOR="1"
MINOR="10"

source ../common.sh

# Image definitions
IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_CONSOLE_PLUGIN="${REGISTRY}/console-plugin:${OCP_DATE}"
IMG_CONSOLE_PLUGIN_COMPAT="${REGISTRY}/console-plugin-compat:${OCP_DATE}"
IMG_FLOWLOGS_PIPELINE="${REGISTRY}/flowlogs-pipeline:${OCP_DATE}"
IMG_CLI="${REGISTRY}/cli:${OCP_DATE}"
IMG_EBPF_AGENT="${REGISTRY}/ebpf-agent:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/bundle:${OCP_DATE}"

IMG_OSE_CLI="$(get_payload_component "cli")"

## Functions

init() {
    submodule_initialize operator release-${OCP_SHORT}
    submodule_initialize console-plugin release-${OCP_SHORT}
    submodule_initialize console-plugin-compat release-${OCP_SHORT}-pf4
    submodule_initialize flowlogs-pipeline release-${OCP_SHORT}
    submodule_initialize cli release-${OCP_SHORT}
    submodule_initialize ebpf-agent release-${OCP_SHORT}
}

deinit() {
    submodule_reset operator release-${OCP_SHORT}
    submodule_reset console-plugin release-${OCP_SHORT}
    submodule_reset console-plugin-compat release-${OCP_SHORT}-pf4
    submodule_reset flowlogs-pipeline release-${OCP_SHORT}
    submodule_reset cli release-${OCP_SHORT}
    submodule_reset ebpf-agent release-${OCP_SHORT}
}

update() {
    submodule_update operator release-${OCP_SHORT} https://github.com/netobserv/network-observability-operator.git
    submodule_update console-plugin release-${OCP_SHORT} https://github.com/netobserv/network-observability-console-plugin.git
    submodule_update console-plugin-compat release-${OCP_SHORT}-pf4 https://github.com/netobserv/network-observability-console-plugin.git
    submodule_update flowlogs-pipeline release-${OCP_SHORT} https://github.com/netobserv/flowlogs-pipeline.git
    submodule_update cli release-${OCP_SHORT} https://github.com/netobserv/network-observability-cli.git
    submodule_update ebpf-agent release-${OCP_SHORT} https://github.com/netobserv/netobserv-ebpf-agent.git
}

build_containers() {
    function build() {
        podman build --build-arg BUILDVERSION=${OCP_DATE} --build-arg BUILDVERSION_Y=${OCP_SHORT} -t $1 -f images/$2.Containerfile ${@:3} $2
    }

    build $IMG_OPERATOR operator
    build $IMG_CONSOLE_PLUGIN console-plugin
    build $IMG_CONSOLE_PLUGIN_COMPAT console-plugin-compat
    build $IMG_FLOWLOGS_PIPELINE flowlogs-pipeline
    build $IMG_CLI cli --build-arg IMG_CLI=$IMG_OSE_CLI
    build $IMG_EBPF_AGENT ebpf-agent
}

push_containers() {
    push_all_images
}

build_bundle() {
    pushd operator

    # Install crdoc if not present
    if [ ! -f "$HOME/go/bin/crdoc" ]; then
      crdoc=$(mktemp -d)
      git clone --depth 1 --branch v0.5.2 https://github.com/fybrik/crdoc.git $crdoc
      pushd $crdoc
      go install .
      popd
      rm -rf $crdoc
    fi

    make bundle VERSION=${OCP_DATE} BUNDLE_VERSION=${OCP_DATE} IMAGE=${IMG_OPERATOR} BUNDLE_IMAGE=${IMG_BUNDLE} \
     "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" NAMESPACE=openshift-netobserv-operator BPF_IMG=${IMG_EBPF_AGENT} \
     FLP_IMG=${IMG_FLOWLOGS_PIPELINE} PLG_IMG=${IMG_CONSOLE_PLUGIN} PLG_COMPAT_IMG=${IMG_CONSOLE_PLUGIN_COMPAT} \
     CRDOC=$HOME/go/bin/crdoc

    podman build -f bundle.Dockerfile -t "${IMG_BUNDLE}" .
    podman push "${IMG_BUNDLE}"

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
