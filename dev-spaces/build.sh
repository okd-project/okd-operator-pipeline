#!/bin/bash

NAMESPACE="dev-spaces"
MAJOR=7
MINOR=117

source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_SERVER="${REGISTRY}/server:${OCP_DATE}"
export IMG_DASHBOARD="${REGISTRY}/dashboard:${OCP_DATE}"
export IMG_PLUGIN_REGISTRY="${REGISTRY}/plugin-registry:${OCP_DATE}"
export IMG_CODE="${REGISTRY}/code:${OCP_DATE}"
export IMG_CODE_SSHD="${REGISTRY}/code-sshd:${OCP_DATE}"
export IMG_JETBRAINS_IDE="${REGISTRY}/jetbrains-ide:${OCP_DATE}"
export IMG_UDI="${REGISTRY}/udi:${OCP_DATE}"
export IMG_TRAEFIK="${REGISTRY}/traefik:${OCP_DATE}"
export IMG_CONFIGBUMP="${REGISTRY}/configbump:${OCP_DATE}"
export IMG_KUBE_RBAC_PROXY="$(get_payload_component kube-rbac-proxy)"
export IMG_OAUTH_PROXY="$(get_payload_component oauth-proxy)"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

## Functions

init() {
    submodule_initialize che-operator 7.117.x
    submodule_initialize che-server 7.117.x
    submodule_initialize che-dashboard 7.117.x
    submodule_initialize che-machine-exec 7.117.x
    submodule_initialize che-code 7.117.x
    submodule_initialize jetbrains-ide-dev-server 7.117.x
    submodule_initialize traefik v3.7
    submodule_initialize configbump 7.117.x
    submodule_initialize stow master
    submodule_initialize header-rewrite-traefik-plugin main
}

deinit() {
    submodule_reset che-operator 7.117.x
    submodule_reset che-server 7.117.x
    submodule_reset che-dashboard 7.117.x
    submodule_reset che-machine-exec 7.117.x
    submodule_reset che-code 7.117.x
    submodule_reset jetbrains-ide-dev-server 7.117.x
    submodule_reset traefik v3.7
    submodule_reset configbump 7.117.x
    submodule_reset stow master
    submodule_reset header-rewrite-traefik-plugin main
}

update() {
    submodule_update che-operator 7.117.x https://github.com/eclipse-che/che-operator.git
    submodule_update che-server 7.117.x https://github.com/eclipse-che/che-server.git
    submodule_update che-dashboard 7.117.x https://github.com/eclipse-che/che-dashboard.git
    submodule_update che-machine-exec 7.117.x https://github.com/eclipse-che/che-machine-exec.git
    submodule_update che-code 7.117.x https://github.com/che-incubator/che-code.git
    submodule_update jetbrains-ide-dev-server 7.117.x https://github.com/che-incubator/jetbrains-ide-dev-server.git
    submodule_update traefik v3.7 https://github.com/traefik/traefik.git
    submodule_update configbump 7.117.x https://github.com/che-incubator/configbump.git
    submodule_update stow master https://github.com/aspiers/stow.git
    submodule_update header-rewrite-traefik-plugin main https://github.com/che-incubator/header-rewrite-traefik-plugin.git
}

build_containers() {
    podman build -t "${IMG_OPERATOR}"       -f operator.Containerfile       .
    podman build -t "${IMG_SERVER}"         -f server.Containerfile         .
    podman build -t "${IMG_DASHBOARD}"      -f dashboard.Containerfile      .
    podman build -t "${IMG_PLUGIN_REGISTRY}" -f pluginregistry.Containerfile .
    podman build -t "${IMG_CODE}"           -f code.Containerfile           .
    podman build -t "${IMG_CODE_SSHD}"      -f code-sshd.Containerfile      .
    podman build -t "${IMG_JETBRAINS_IDE}"  -f jetbrains-ide.Containerfile  .
    podman build -t "${IMG_UDI}"            -f udi.Containerfile            .
    podman build -t "${IMG_TRAEFIK}"        -f traefik.Containerfile        .
    podman build -t "${IMG_CONFIGBUMP}"     -f configbump.Containerfile     .
}

push_containers() {
    push_all_images
}

build_bundle() {
    convert_all_images_to_digest

    pushd che-operator

    # ── Step 1: Update config/manager/manager.yaml env vars ──────────────────
    # These feed into kustomize → operator-sdk → CSV deployment spec.
    yq e -i "
      .spec.template.spec.containers[0].env |=
        map(
          select(.name == \"RELATED_IMAGE_che_server\").value                         = \"${IMG_SERVER}\" |
          select(.name == \"RELATED_IMAGE_dashboard\").value                          = \"${IMG_DASHBOARD}\" |
          select(.name == \"RELATED_IMAGE_plugin_registry\").value                    = \"${IMG_PLUGIN_REGISTRY}\" |
          select(.name == \"RELATED_IMAGE_single_host_gateway\").value                = \"${IMG_TRAEFIK}\" |
          select(.name == \"RELATED_IMAGE_single_host_gateway_config_sidecar\").value = \"${IMG_CONFIGBUMP}\" |
          select(.name == \"RELATED_IMAGE_gateway_authentication_sidecar\").value     = \"${IMG_OAUTH_PROXY}\" |
          select(.name == \"RELATED_IMAGE_gateway_authorization_sidecar\").value      = \"${IMG_KUBE_RBAC_PROXY}\"
        )
    " config/manager/manager.yaml

    # Also update CHE_DEFAULT_SPEC_DEVENVIRONMENTS_DEFAULTCOMPONENTS — JSON string
    # containing the default UDI image reference.
    sed -i "s|quay.io/devfile/universal-developer-image:[^\"]*|${IMG_UDI}|g" \
        config/manager/manager.yaml

    # ── Step 2: Update editors-definitions YAML files ────────────────────────
    # These feed into the RELATED_IMAGE_editor_definition_* env vars in the CSV.
    # Only update -latest.yaml files (those appear in the production bundle).
    for f in editors-definitions/*-latest.yaml editors-definitions/jetbrains-sshd-*.yaml; do
        # VS Code injector
        sed -i "s|quay.io/che-incubator/che-code:[^ \"']*|${IMG_CODE}|g" "$f"
        # VS Code SSHD
        sed -i "s|quay.io/che-incubator/che-code-sshd:[^ \"']*|${IMG_CODE_SSHD}|g" "$f"
        # JetBrains IDE dev server (all variants: CLion, GoLand, IDEA, etc.)
        sed -i "s|quay.io/che-incubator/che-idea-dev-server:[^ \"']*|${IMG_JETBRAINS_IDE}|g" "$f"
        # Universal Developer Image runtime
        sed -i "s|quay.io/devfile/universal-developer-image:[^ \"']*|${IMG_UDI}|g" "$f"
    done

    # ── Step 3: Update editor definition env vars in committed bundle CSV ───────
    # make bundle --overwrite preserves RELATED_IMAGE_editor_definition_* from
    # the existing bundle CSV (these are absent from kustomize/manager.yaml).
    # Update them here so make bundle's generated spec.relatedImages uses OKD
    # images. Images not rebuilt by OKD (ubi9-minimal, ttyd, che-code-server)
    # are left unchanged.
    local csv_path="bundle/stable/eclipse-che/manifests/che-operator.clusterserviceversion.yaml"
    sed -i -E "s|quay.io/che-incubator/che-code@sha256:[a-f0-9]+|${IMG_CODE}|g"                     "${csv_path}"
    sed -i -E "s|quay.io/che-incubator/che-idea-dev-server@sha256:[a-f0-9]+|${IMG_JETBRAINS_IDE}|g" "${csv_path}"
    sed -i -E "s|quay.io/devfile/universal-developer-image@sha256:[a-f0-9]+|${IMG_UDI}|g"           "${csv_path}"
    sed -i -E "s|quay.io/che-incubator/che-code-sshd@sha256:[a-f0-9]+|${IMG_CODE_SSHD}|g"          "${csv_path}"

    # ── Step 4: make bundle ───────────────────────────────────────────────────
    # Runs generate → manifests → kustomize → operator-sdk generate bundle →
    # operator-sdk bundle validate → injects IMG as containerImage in CSV.
    # operator-sdk auto-populates spec.relatedImages from all RELATED_IMAGE_*
    # env vars in the deployment spec; no manual injection needed.
    make bundle \
        CHANNEL=stable \
        IMG="${IMG_OPERATOR}" \
        INCREMENT_BUNDLE_VERSION=false \
        IMAGE_TOOL=podman \
        OPERATOR_SDK="$(command -v operator-sdk)"

    # ── Step 5: Build and push the bundle image ───────────────────────────────
    make bundle-build \
        CHANNEL=stable \
        BUNDLE_IMG="${IMG_BUNDLE}" \
        IMAGE_TOOL=podman

    podman push "${IMG_BUNDLE}"

    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
