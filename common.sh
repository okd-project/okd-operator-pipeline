#!/bin/bash

set -euox pipefail

BASE_REGISTRY=${BASE_REGISTRY:-"quay.io/okderators"}
OKD_VERSION=${OKD_VERSION:-"4.18.0-okd-scos.10"}
OKD_RELEASE=quay.io/okd/scos-release:${OKD_VERSION}
CHANNEL=${CHANNEL:-alpha}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL:-alpha}
BUNDLE_METADATA_OPTS="--channels=${CHANNEL} --default-channel=${DEFAULT_CHANNEL} --use-image-digests"

MAJOR=${MAJOR:-"$(echo "${OKD_VERSION}" | cut -d. -f1)"}
MINOR=${MINOR:-"$(echo "${OKD_VERSION}" | cut -d. -f2)"}
OCP_SHORT="${MAJOR}.${MINOR}"
DATE=${DATE:-"$(date +%Y-%m-%d-%H%M%S)"}
OCP_DATE="${MAJOR}.${MINOR}.0-${DATE}"

get_payload_component() {
  local -r component="$1"

  oc adm release info --image-for="${component}" "${OKD_RELEASE}"
}

submodule_exists() {
  local -r name="$1"

  # Check for directory
  if [ -d "${name}" ]; then
    pushd "${name}"
    GIT_DIR="$(git rev-parse --git-dir)"
    CURRENT_DIR="$(pwd)"
    popd
    # Check if the current directory is equal to the git directory
    if [ "${GIT_DIR}" = "${CURRENT_DIR}" ]; then
      return 1
    fi
  fi

  return 0
}

submodule_reset() {
  local -r name="$1"
  local -r branch="$2"

  # Check if the submodule exists
  EXISTS=$(submodule_exists "${name}")
  if [ "${EXISTS}" = true ]; then
    git clean -fdx
    git reset --hard origin/${branch}
    git submodule deinit -f "${name}"
  fi
}

submodule_initialize() {
  local -r name="$1"
  local -r branch="$2"

  submodule_reset "${name}" "${branch}"

  git submodule update --init --recursive "${name}" || true

  # Check for patch file
  if [ -f "patches/${name}.patch" ]; then
    pushd "${name}"
    git am -3 "../patches/${name}.patch"
    popd
  fi
}

apply_patch() {
  local -r name="$1"
  local -r branch="$2"

  # Check if the submodule is already initialized
  if [ ! -d "${name}" ]; then
    git submodule update --init --recursive "${name}"
  fi

  pushd "${name}"
  # Reset any previous patches
  git clean -fdx
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

replace_csv_product() {
  local csv_file="$1"
  local path="$2"

  # YQ get the value from the yaml
  local value=$(yq e "$path" "$csv_file")
  # Look for instances of OpenShift and replace with OKD, OCP => OKD, and Red Hat to nothing
  value=$(echo "$value" | sed -e 's/OpenShift/OKD/g' -e 's/OCP/OKD/g' -e 's/Red Hat//g')
  # YQ set the value back to the yaml
  yq e -i "$path = \"$value\"" "$csv_file"
}

set_csv_value() {
  local csv_file="$1"
  local path="$2"
  local value="$3"

  # YQ set the value back to the yaml
  yq e -i "$path = \"$value\"" "$csv_file"
}
