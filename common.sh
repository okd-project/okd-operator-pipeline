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
    local recorded_hash
    dir_name=$(basename "$(pwd)")
    recorded_hash=$(git rev-parse HEAD:"${dir_name}/${name}" 2>/dev/null || echo "")

    if [ -z "$recorded_hash" ]; then
      echo "Error: Could not find recorded commit for ${name}. Ensure submodule is registered."
      return 1
    fi

    # Clean untracked files and directories (removes any patch artifacts)
    git -C "${name}" clean -fdx

    # Explicitly discard all local changes in the working tree (reverts applied patches)
    git -C "${name}" checkout -- .

    # Reset top-level submodule to the exact recorded commit (discards any remaining changes)
    git -C "${name}" checkout -f "$recorded_hash"
    git -C "${name}" reset --hard "$recorded_hash"

    # Recursively handle nested submodules with the same steps
    git -C "${name}" submodule foreach --recursive '
      git clean -fdx;
      git checkout -- .;
      local nested_hash=$(git rev-parse HEAD:"$path" 2>/dev/null || echo "");
      if [ -n "$nested_hash" ]; then
        git checkout -f "$nested_hash";
        git reset --hard "$nested_hash";
      fi
    '
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

main() {
  # Standardized main execution flow for operator build scripts
  # Calls init(), build_containers(), push_containers(), build_bundle(), and deinit()
  # if they are defined as functions in the sourcing script
  #
  # Usage:
  #   main                           # Run all steps
  #   main build_containers          # Run only build_containers
  #   main init build_containers     # Run init, then build_containers
  #   main build_containers push_containers build_bundle  # Run specific steps in order

  # If no arguments provided, run all steps in standard order
  if [ $# -eq 0 ]; then
    if declare -f init > /dev/null; then
      init
    fi

    if declare -f build_containers > /dev/null; then
      build_containers
    fi

    if declare -f push_containers > /dev/null; then
      push_containers
    fi

    if declare -f build_bundle > /dev/null; then
      build_bundle
    fi

    if declare -f deinit > /dev/null; then
      deinit
    fi
  else
    # Run only the specified steps in the order given
    for step in "$@"; do
      if declare -f "$step" > /dev/null; then
        echo "Running step: $step"
        "$step"
      else
        echo "Warning: Function '$step' is not defined, skipping"
      fi
    done
  fi
}
