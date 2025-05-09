#!/bin/bash


BASE_REGISTRY=${BASE_REGISTRY:-"quay.io/okderators"}
OKD_VERSION=${OKD_VERSION:-"4.18.0-okd-scos.9"}
OKD_RELEASE=quay.io/okd/scos-release:${OKD_VERSION}
CHANNEL=${CHANNEL:-alpha}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL:-alpha}
BUNDLE_METADATA_OPTS="--channels=${CHANNEL} --default-channel=${DEFAULT_CHANNEL} --use-image-digests"

MAJOR=$(echo "${OKD_VERSION}" | cut -d. -f1)
MINOR=$(echo "${OKD_VERSION}" | cut -d. -f2)
OCP_SHORT="${MAJOR}.${MINOR}"
DATE=$(date +%Y-%m-%d-%H%M%S)
OCP_DATE="${MAJOR}.${MINOR}.0-${DATE}"

get_payload_component() {
  local -r component="$1"

  oc adm release info --image-for="${component}" "${OKD_RELEASE}"
}

apply_patch() {
  local -r name="$1"
  local -r branch="$2"

  # Make sure only this submodule is initialized
  git submodule update --init --recursive "${name}"

  pushd "${name}"
  # Reset any previous patches
  git reset --hard origin/${branch}
  # Apply patch to git repo
  git am -3 "../patches/${name}.patch"
  popd
}

export_image_digest() {
    local varname="$1"
    local url="$2"
    local digest
    local value=

    if [ "$EMPTY_IS_VALID" = 1 ] ; then
        [ -n "${!varname+set}" ] && return 0
    else
        [ -n "${!varname}" ] && return 0
    fi

    if [ -n "$url" ] ; then
        digest="$(skopeo inspect "docker://$url" -f '{{.Name}}@{{.Digest}}')" || :
        if [ -z "$digest" ] ; then
            echo "Failure to detect \$$varname at $url. Set the variable"
            return 1
        fi
        value="$digest"
    fi

    export "$varname=$value"
}