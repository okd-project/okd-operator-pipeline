#!/bin/bash

set -euox pipefail

# Error if NAMESPACE is not set
if [ -z "${NAMESPACE:-}" ]; then
  echo "NAMESPACE is not set. Please set it to the target namespace."
  exit 1
fi

BASE_REGISTRY=${BASE_REGISTRY:-"quay.io/okderators"}
OKD_VERSION=${OKD_VERSION:-"4.20.0-okd-scos.6"}
REGISTRY="${BASE_REGISTRY}/$NAMESPACE"
OKD_RELEASE=quay.io/okd/scos-release:${OKD_VERSION}
CHANNEL=${CHANNEL:-alpha}
DEFAULT_CHANNEL=${DEFAULT_CHANNEL:-alpha}
BUNDLE_METADATA_OPTS="--channels=${CHANNEL} --default-channel=${DEFAULT_CHANNEL} --use-image-digests"

MAJOR=${MAJOR:-"$(echo "${OKD_VERSION}" | cut -d. -f1)"}
MINOR=${MINOR:-"$(echo "${OKD_VERSION}" | cut -d. -f2)"}
OCP_SHORT="${MAJOR}.${MINOR}"
DATE=${DATE:-"$(date +%Y-%m-%d-%H%M%S)"}
OCP_DATE="${MAJOR}.${MINOR}.0-${DATE}"
PREV_MINOR="${MAJOR}.$((MINOR - 1))"

RELEASE_INFO="$(oc adm release info ${OKD_RELEASE} -o='json')"

get_payload_component() {
  local -r component="$1"

  echo "$RELEASE_INFO" | jq -r --arg name "$component" \
   '.. | objects | .spec?.tags? // empty | .[] | select(.name==$name) | .from.name'
}

submodule_exists() {
  local -r name="$1"

  # Check for directory
  if [ -d "${name}" ]; then
    if [ -d "$name/.git" ] || [ -f "$name/.git" ]; then
      echo 1
      return 0
    fi
  fi

  echo 0
}

submodule_reset() {
  local -r name="$1"
  local -r branch="$2"

  # Check if the submodule exists
  EXISTS=$(submodule_exists "${name}")
  if [ "${EXISTS}" = "1" ]; then
    git -C "$name" clean -fdx
    git -C "$name" reset --hard origin/${branch}
    # Reset all nested submodules
    git -C "${name}" submodule foreach --recursive 'git clean -fdx; git reset --hard'
#    git submodule deinit -f "${name}"
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

submodule_update() {
  local -r name="$1"
  local -r branch="$2"
  local -r url="$3"


  EXISTS=$(submodule_exists "${name}")
  if [ "${EXISTS}" = "1" ]; then
    git -C "$name" clean -fdx
    git -C "$name" fetch origin "${branch}"
    git -C "$name" reset --hard origin/${branch}
  fi

  git submodule update --init --recursive "${name}" || true

  git submodule add -f -b ${branch} ${url} ${name} || true

  pushd "${name}"
  git remote set-url origin "${url}"
  git fetch origin "${branch}"
  git reset --hard "origin/${branch}"
  popd
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

function push_all_images() {
  for img in $(compgen -v IMG_); do
      # Ignore the bundle image
      if [[ $img == IMG_BUNDLE* ]]; then
          continue
      fi
      # Ignore if value does not start with "quay.io/okderators/"
      if [[ ${!img} != $REGISTRY* ]]; then
          continue
      fi
      if [[ $img == IMG_* ]]; then
          echo "Pushing ${!img}..."
          podman push "${!img}"
      fi
  done
}

function convert_all_images_to_digest() {
  # Convert all IMG variables to digest format
  # Create a temporary directory to store results
  local tmp_dir=$(mktemp -d)
  local pids=()
  
  for img in $(compgen -v IMG_); do
      # Ignore the bundle image
      if [[ $img == IMG_BUNDLE* ]]; then
          continue
      fi
      if [[ $img == IMG_* ]]; then
          # Run skopeo inspect in background and save result to a temp file
          (
              # Convert to image digest URL
              digest_img=$(skopeo inspect --no-tags "docker://${!img}" --format '{{.Name}}@{{.Digest}}')
              if [[ -n $digest_img ]]; then
                  echo "export $img=\"$digest_img\"" > "$tmp_dir/$img"
              fi
          ) &
          # Store the PID of the background process
          pids+=($!)
      fi
  done
  
  # Wait for all background processes to complete
  for pid in "${pids[@]}"; do
      wait "$pid"
  done
  
  # Source all the temporary files to set the environment variables
  for result_file in "$tmp_dir"/*; do
      if [[ -f "$result_file" ]]; then
          source "$result_file"
      fi
  done
  
  # Clean up temporary directory
  rm -rf "$tmp_dir"
}
