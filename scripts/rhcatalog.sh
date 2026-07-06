#!/bin/bash

set -euo pipefail

GRAPHQL_URL="${GRAPHQL_URL:-https://catalog.redhat.com/api/containers/graphql/}"

# Mapping from OKD operator directory names to Red Hat catalog package names.
# Discovered via find_operators queries against the catalog API.
declare -A OKD_TO_RH_PACKAGE=(
  ["acm"]="advanced-cluster-management"
  ["cert-manager"]="openshift-cert-manager-operator"
  ["cluster-logging"]="cluster-logging"
  ["cluster-observability"]="cluster-observability-operator"
  ["data-foundation"]="odf-operator"
  ["external-secrets"]="external-secrets-operator"
  ["gitops"]="openshift-gitops-operator"
  ["ingress-node-firewall"]="ingress-node-firewall"
  ["local-storage"]="local-storage-operator"
  ["lvms"]="lvms-operator"
  ["metallb"]="metallb-operator"
  ["multicluster-engine"]="multicluster-engine"
  ["network-observability"]="netobserv-operator"
  ["nmstate"]="kubernetes-nmstate-operator"
  ["node-feature-discovery"]="nfd"
  ["oadp"]="redhat-oadp-operator"
  ["service-mesh"]="servicemeshoperator"
  ["sr-iov"]="sriov-network-operator"
  ["vertical-pod-autoscaler"]="vertical-pod-autoscaler"
  ["web-terminal"]="web-terminal"
  ["dev-spaces"]="devspaces"
  ["devworkspace"]="devworkspace-operator"
)

# graphql_query <query-string>
# POSTs a raw GraphQL query and returns the JSON response.
graphql_query() {
  local -r query="${1:?query string required}"
  curl -sf -X POST \
    -H "Content-Type: application/json" \
    --data "$(jq -n --arg q "$query" '{"query": $q}')" \
    "$GRAPHQL_URL"
}

# find_operators <pattern>
# Find operator package names matching a case-insensitive pattern.
find_operators() {
  local -r pattern="${1:?Usage: find_operators <pattern>}"
  graphql_query \
    "{ find_operator_packages(filter: {package_name: {iregex: \"${pattern}\"}}) { data { package_name } } }" \
    | jq -r '.data.find_operator_packages.data[].package_name'
}

# get_bundles <package> [ocp_version] [page_size]
# Get operator bundles for a package, optionally filtered by OCP version.
# Returns raw JSON with .data.find_operator_bundles.
get_bundles() {
  local -r package="${1:?Usage: get_bundles <package> [ocp_version] [page_size]}"
  local ocp_version="${2:-}"
  local page_size="${3:-20}"
  local query
  if [[ -n "$ocp_version" ]]; then
    query="{ find_operator_bundles(package: \"${package}\", ocp_version: \"${ocp_version}\", page_size: ${page_size}) { data { package channel_name version bundle_path csv_name ocp_version related_images { name image } } total } }"
  else
    query="{ find_operator_bundles(package: \"${package}\", page_size: ${page_size}) { data { package channel_name version bundle_path csv_name ocp_version related_images { name image } } total } }"
  fi
  graphql_query "$query"
}

# get_latest_bundle <package> [ocp_version]
# Return the single most recent bundle entry as JSON.
get_latest_bundle() {
  local -r package="${1:?Usage: get_latest_bundle <package> [ocp_version]}"
  local ocp_version="${2:-}"
  get_bundles "$package" "$ocp_version" 1 | jq '.data.find_operator_bundles.data[0]'
}

# get_bundle_images <package> [ocp_version]
# Print tab-separated name/image pairs from the latest bundle's related_images.
get_bundle_images() {
  local -r package="${1:?Usage: get_bundle_images <package> [ocp_version]}"
  local ocp_version="${2:-}"
  get_bundles "$package" "$ocp_version" 1 \
    | jq -r '.data.find_operator_bundles.data[0].related_images[] | "\(.name)\t\(.image)"'
}

# get_image_labels <image-id>
# Get parsed_data labels and env vars for a container image by its MongoDB _id.
# Image IDs can be found in the _id field returned by get_bundles, get_repo_images, etc.
get_image_labels() {
  local -r id="${1:?Usage: get_image_labels <mongodb-image-id>}"
  graphql_query \
    "{ get_image(id: \"${id}\") { _id repositories { registry repository tags { name } } parsed_data { labels { name value } env_variables { name value } } } }" \
    | jq '.data.get_image'
}

# get_image_layers <image-id>
# Get layer digests and sizes for a container image by its MongoDB _id.
get_image_layers() {
  local -r id="${1:?Usage: get_image_layers <mongodb-image-id>}"
  graphql_query \
    "{ get_image(id: \"${id}\") { _id sum_layer_size_bytes parsed_data { layers uncompressed_layer_sizes { layer_id size_bytes } } } }" \
    | jq '.data.get_image'
}

# get_image_files <image-id> [page_size]
# List files extracted from within a container image (populated for a subset of images).
get_image_files() {
  local -r id="${1:?Usage: get_image_files <mongodb-image-id> [page_size]}"
  local page_size="${2:-100}"
  graphql_query \
    "{ find_image_files(id: \"${id}\", page_size: ${page_size}) { data { filename content key } total } }" \
    | jq '.data.find_image_files'
}

# find_image_by_digest <full-image-ref>
# Resolve a full image ref (registry/repo@sha256:...) to its MongoDB _id by matching
# the digest against manifest_list_digest or manifest_schema2_digest on catalog entries.
# Falls back to the most recent image in the repository if no exact match is found.
find_image_by_digest() {
  local -r ref="${1:?Usage: find_image_by_digest <full-image-ref>}"

  local without_digest="${ref%%@*}"
  local registry="${without_digest%%/*}"
  local repository="${without_digest#*/}"
  local digest="${ref#*@}"

  # Catalog indexes content under registry.access.redhat.com regardless of pull URL
  [[ "$registry" == "registry.redhat.io" ]] && registry="registry.access.redhat.com"

  local images
  images=$(graphql_query \
    "{ find_repository_images_by_registry_path(registry: \"${registry}\", repository: \"${repository}\", sort_by: [{field: \"_id\", order: DESC}], page_size: 200) { data { _id repositories { manifest_list_digest manifest_schema2_digest } } } }")

  # Match by manifest_list_digest (multi-arch) or manifest_schema2_digest (single-arch).
  # page_size 200 covers repos that receive frequent backport builds (4 arches × ~50 builds)
  # while still finding bundles from a few months back relative to the most recent build.
  local id
  id=$(echo "$images" | jq -r --arg d "$digest" '
    .data.find_repository_images_by_registry_path.data[] |
    select(any(.repositories[]?;
      (.manifest_list_digest == $d) or (.manifest_schema2_digest == $d)
    )) | ._id' | head -1)

  if [[ -z "$id" ]]; then
    # The catalog only indexes publicly-accessible images; subscription-gated images
    # may not appear. Fall back to the most recent indexed version.
    echo "warning: exact digest not in catalog for ${ref##*/}, using most recent indexed version" >&2
    id=$(echo "$images" | jq -r '.data.find_repository_images_by_registry_path.data[0]._id // ""')
  fi

  echo "$id"
}

# _parse_repo_path <repo-path>
# Internal helper: parse a repo-path into registry and repository variables.
# Sets caller-local variables: registry, repository.
# Accepts:
#   openshift4/metallb-rhel9-operator                              (short, no registry)
#   registry.access.redhat.com/openshift4/metallb-rhel9-operator   (full)
#   registry.redhat.io/openshift4/foo@sha256:...                   (bundle-style, remapped)
_parse_repo_path() {
  local path="${1%%@*}"       # strip @sha256:... digest suffix
  registry="${path%%/*}"      # first slash-delimited component
  repository="${path#*/}"     # everything after first slash
  # If registry component has no dot it's not a hostname (e.g. "openshift4") — short form
  if [[ "$registry" != *.* ]]; then
    repository="$path"
    registry="registry.access.redhat.com"
  fi
  # Remap subscription registry to public catalog registry
  if [[ "$registry" == "registry.redhat.io" ]]; then
    registry="registry.access.redhat.com"
  fi
}

# find_image_by_tag <repo-path> <tag>
# Find an image by its exact tag. Returns the catalog JSON object with _id, manifest
# digest, and tag list. <repo-path> accepts short, full, or bundle-style refs.
find_image_by_tag() {
  local -r repo_path="${1:?Usage: find_image_by_tag <repo-path> <tag>}"
  local -r tag="${2:?Usage: find_image_by_tag <repo-path> <tag>}"
  local registry repository
  _parse_repo_path "$repo_path"
  graphql_query \
    "{ find_repository_images_by_registry_path_tag(registry: \"${registry}\", repository: \"${repository}\", tag: \"${tag}\", page_size: 1) { data { _id repositories { manifest_list_digest tags { name } } } } }" \
    | jq '.data.find_repository_images_by_registry_path_tag.data[0]'
}

# list_repo_tags <repo-path> [pattern]
# List human-readable tags for a repository, optionally filtered by a case-insensitive
# regex pattern. Hex-only digest tags are suppressed. <repo-path> accepts short, full,
# or bundle-style refs.
list_repo_tags() {
  local -r repo_path="${1:?Usage: list_repo_tags <repo-path> [pattern]}"
  local pattern="${2:-}"
  local registry repository
  _parse_repo_path "$repo_path"

  local tag_filter=""
  if [[ -n "$pattern" ]]; then
    tag_filter=", {tags_elemMatch: {and: [{name: {iregex: \"${pattern}\"}}]}}"
  fi

  graphql_query \
    "{ find_images(filter: {repositories_elemMatch: {and: [{registry: {eq: \"${registry}\"}}, {repository: {eq: \"${repository}\"}}${tag_filter}]}}, sort_by: [{field: \"_id\", order: DESC}], page_size: 20) { data { repositories { tags { name } } } } }" \
    | jq -r '
        [
          .data.find_images.data[].repositories[].tags[].name |
          select(test("^[0-9a-f]{64}$") | not)
        ] | unique | sort | .[]
      '
}

# get_containerfile_by_tag <repo-path> <tag>
# Fetch and print the Dockerfile for a specific tag. <repo-path> accepts short, full,
# or bundle-style refs.
get_containerfile_by_tag() {
  local -r repo_path="${1:?Usage: get_containerfile_by_tag <repo-path> <tag>}"
  local -r tag="${2:?Usage: get_containerfile_by_tag <repo-path> <tag>}"

  local result
  result=$(find_image_by_tag "$repo_path" "$tag")

  local id
  id=$(echo "$result" | jq -r '._id // ""')

  if [[ -z "$id" || "$id" == "null" ]]; then
    echo "error: no image found for tag '${tag}' in ${repo_path}" >&2
    return 1
  fi

  local files_json
  files_json=$(get_image_files "$id")

  local total
  total=$(echo "$files_json" | jq '.total // 0')

  if [[ "$total" -eq 0 ]]; then
    echo "(no Containerfile available for this image)"
    return 0
  fi

  local dockerfile
  dockerfile=$(echo "$files_json" | jq -r '
    [.data[] | select(.key == "buildfile")] |
    if length > 0 then .[0].content else null end
  ')

  if [[ "$dockerfile" == "null" ]]; then
    dockerfile=$(echo "$files_json" | jq -r '
      [.data[] | select(.filename | ascii_downcase | test("dockerfile|containerfile"))] |
      if length > 0 then .[0].content else null end
    ')
  fi

  if [[ "$dockerfile" == "null" ]]; then
    echo "(no Dockerfile/Containerfile found; available files:)"
    echo "$files_json" | jq -r '.data[] | "  \(.filename) (key: \(.key))"'
  else
    echo "$dockerfile"
  fi
}

# get_operator_containerfiles <package-or-dir> [ocp_version]
# Fetch and print Dockerfiles for every component image in an operator bundle.
# Accepts either an OKD directory name (e.g. "sr-iov") or an RH package name.
get_operator_containerfiles() {
  local -r arg="${1:?Usage: get_operator_containerfiles <package-or-dir> [ocp_version]}"
  local ocp_version="${2:-}"
  local package
  package=$(okd_to_package "$arg")

  local bundle
  bundle=$(get_bundles "$package" "$ocp_version" 1)

  local bundle_ver
  bundle_ver=$(echo "$bundle" | jq -r '.data.find_operator_bundles.data[0].version')
  echo "=== ${package} ${bundle_ver}${ocp_version:+ (ocp_version: ${ocp_version})} ==="
  echo ""

  while IFS=$'\t' read -r name image_ref; do
    echo "--- ${name} ---"
    echo "    ${image_ref}"
    echo ""

    local id
    id=$(find_image_by_digest "$image_ref") || id=""

    if [[ -z "$id" || "$id" == "null" ]]; then
      echo "(image not found in catalog)" >&2
      echo ""
      continue
    fi

    local files_json
    files_json=$(get_image_files "$id") || files_json='{"data":[],"total":0}'

    local total
    total=$(echo "$files_json" | jq '.total // 0')

    if [[ "$total" -eq 0 ]]; then
      echo "(no Containerfile available for this image)"
      echo ""
      continue
    fi

    # Prefer files tagged with key="buildfile", then filename matching Dockerfile/Containerfile
    local dockerfile
    dockerfile=$(echo "$files_json" | jq -r '
      [.data[] | select(.key == "buildfile")] |
      if length > 0 then .[0].content else null end
    ')

    if [[ "$dockerfile" == "null" ]]; then
      dockerfile=$(echo "$files_json" | jq -r '
        [.data[] | select(.filename | ascii_downcase | test("dockerfile|containerfile"))] |
        if length > 0 then .[0].content else null end
      ')
    fi

    if [[ "$dockerfile" == "null" ]]; then
      echo "(no Dockerfile/Containerfile found; available files:)"
      echo "$files_json" | jq -r '.data[] | "  \(.filename) (key: \(.key))"'
    else
      echo "$dockerfile"
    fi
    echo ""
  done < <(echo "$bundle" | \
    jq -r '.data.find_operator_bundles.data[0].related_images[] | select(.name != "") | "\(.name)\t\(.image)"')
}

# dump_operator_containerfiles <package-or-dir> <tag> <output-dir>
# Write Dockerfiles for every component image in an operator bundle to individual files.
# <tag> is applied to each component's repository (e.g. "v4.21.0").
# OCP version is derived from the tag for the bundle lookup (v4.21.0 -> 4.21).
dump_operator_containerfiles() {
  local -r arg="${1:?Usage: dump_operator_containerfiles <package-or-dir> <tag> <output-dir>}"
  local -r tag="${2:?Usage: dump_operator_containerfiles <package-or-dir> <tag> <output-dir>}"
  local -r output_dir="${3:?Usage: dump_operator_containerfiles <package-or-dir> <tag> <output-dir>}"
  local package
  package=$(okd_to_package "$arg")

  # Derive OCP version from tag: "v4.21.0[-...]" -> "4.21"
  local ocp_version=""
  if [[ "$tag" =~ ^v([0-9]+)\.([0-9]+) ]]; then
    ocp_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
  fi

  local bundle
  bundle=$(get_bundles "$package" "$ocp_version" 1)

  local bundle_ver
  bundle_ver=$(echo "$bundle" | jq -r '.data.find_operator_bundles.data[0].version // "unknown"')

  if [[ "$bundle_ver" == "null" || "$bundle_ver" == "unknown" ]]; then
    echo "error: no bundle found for ${package}${ocp_version:+ (ocp_version: ${ocp_version})}" >&2
    return 1
  fi

  mkdir -p "$output_dir"
  echo "=== ${package} ${bundle_ver} — writing to ${output_dir} ==="
  echo ""

  local written=0 skipped=0
  while IFS=$'\t' read -r name image_ref; do
    local registry repository
    _parse_repo_path "$image_ref"
    local repo_path="${registry}/${repository}"

    local dockerfile
    dockerfile=$(get_containerfile_by_tag "$repo_path" "$tag" 2>/dev/null) || dockerfile=""

    if [[ -z "$dockerfile" || "$dockerfile" == "(no Containerfile available for this image)" ]]; then
      echo "  skip  ${name}  (tag '${tag}' not found in catalog)" >&2
      (( skipped++ )) || true
      continue
    fi

    local outfile="${output_dir%/}/${name}.Dockerfile"
    printf '%s\n' "$dockerfile" > "$outfile"
    echo "  wrote ${outfile}"
    (( written++ )) || true
  done < <(echo "$bundle" | \
    jq -r '.data.find_operator_bundles.data[0].related_images[] | select(.name != "") | "\(.name)\t\(.image)"')

  echo ""
  echo "Done: ${written} written, ${skipped} skipped."
}

# find_repos <pattern>
# Find container repositories whose path matches a case-insensitive pattern.
# Prints registry/repository paths, one per line.
find_repos() {
  local -r pattern="${1:?Usage: find_repos <pattern>}"
  graphql_query \
    "{ find_repositories(filter: {repository: {iregex: \"${pattern}\"}}, page_size: 20) { data { _id registry repository description published namespace architectures } } }" \
    | jq -r '.data.find_repositories.data[] | "\(.registry)/\(.repository)"'
}

# get_repo_images <registry> <repository> [page_size]
# Get images in a specific registry/repository path with labels.
get_repo_images() {
  local -r registry="${1:?Usage: get_repo_images <registry> <repository> [page_size]}"
  local -r repository="${2:?Usage: get_repo_images <registry> <repository> [page_size]}"
  local page_size="${3:-10}"
  graphql_query \
    "{ find_repository_images_by_registry_path(registry: \"${registry}\", repository: \"${repository}\", page_size: ${page_size}) { data { _id image_id repositories { registry repository tags { name } } parsed_data { labels { name value } layers } } } }" \
    | jq '.data.find_repository_images_by_registry_path'
}

# okd_to_package <dir-name>
# Convert an OKD operator directory name to its Red Hat catalog package name.
# Returns the input unchanged if no mapping is found.
okd_to_package() {
  local -r dir="${1:?Usage: okd_to_package <dir-name>}"
  echo "${OKD_TO_RH_PACKAGE[$dir]:-$dir}"
}

# compare_versions <package> <ocp_ver1> <ocp_ver2>
# Diff the related images between two OCP versions of an operator bundle.
# Shows added, removed, and updated component images.
compare_versions() {
  local -r package="${1:?Usage: compare_versions <package> <ocp_ver1> <ocp_ver2>}"
  local -r ver1="${2:?Usage: compare_versions <package> <ocp_ver1> <ocp_ver2>}"
  local -r ver2="${3:?Usage: compare_versions <package> <ocp_ver1> <ocp_ver2>}"

  local raw1 raw2
  raw1=$(get_bundles "$package" "$ver1" 1)
  raw2=$(get_bundles "$package" "$ver2" 1)

  local bundle1 bundle2
  bundle1=$(echo "$raw1" | jq -r '.data.find_operator_bundles.data[0] | "\(.version) (channel: \(.channel_name))"')
  bundle2=$(echo "$raw2" | jq -r '.data.find_operator_bundles.data[0] | "\(.version) (channel: \(.channel_name))"')

  echo "=== ${package} ==="
  echo "  ${ver1}: ${bundle1}"
  echo "  ${ver2}: ${bundle2}"
  echo ""

  local names1 names2
  # Filter out the bundle image itself (name is empty string in related_images)
  names1=$(echo "$raw1" | jq -r '.data.find_operator_bundles.data[0].related_images[] | select(.name != "") | .name' | sort)
  names2=$(echo "$raw2" | jq -r '.data.find_operator_bundles.data[0].related_images[] | select(.name != "") | .name' | sort)

  local removed added common
  removed=$(comm -23 <(echo "$names1") <(echo "$names2")) || true
  added=$(comm -13 <(echo "$names1") <(echo "$names2")) || true
  common=$(comm -12 <(echo "$names1") <(echo "$names2")) || true

  if [[ -n "$removed" ]]; then
    echo "--- Removed ---"
    while IFS= read -r name; do
      local img
      img=$(echo "$raw1" | jq -r --arg n "$name" \
        '.data.find_operator_bundles.data[0].related_images[] | select(.name == $n) | .image')
      echo "  - ${name}"
      echo "      ${img}"
    done <<< "$removed"
    echo ""
  fi

  if [[ -n "$added" ]]; then
    echo "+++ Added +++"
    while IFS= read -r name; do
      local img
      img=$(echo "$raw2" | jq -r --arg n "$name" \
        '.data.find_operator_bundles.data[0].related_images[] | select(.name == $n) | .image')
      echo "  + ${name}"
      echo "      ${img}"
    done <<< "$added"
    echo ""
  fi

  if [[ -n "$common" ]]; then
    local updated_header_shown=false
    while IFS= read -r name; do
      local img1 img2
      img1=$(echo "$raw1" | jq -r --arg n "$name" \
        '.data.find_operator_bundles.data[0].related_images[] | select(.name == $n) | .image')
      img2=$(echo "$raw2" | jq -r --arg n "$name" \
        '.data.find_operator_bundles.data[0].related_images[] | select(.name == $n) | .image')
      if [[ "$img1" != "$img2" ]]; then
        if [[ "$updated_header_shown" == false ]]; then
          echo "~~~ Updated ~~~"
          updated_header_shown=true
        fi
        echo "  ~ ${name}"
        echo "      was: ${img1}"
        echo "      now: ${img2}"
      fi
    done <<< "$common"
    if [[ "$updated_header_shown" == true ]]; then echo ""; fi
  fi

  if [[ -z "$removed" && -z "$added" ]]; then
    echo "(no component additions or removals between ${ver1} and ${ver2})"
  fi
}

# operator_summary <package-or-dir> [ocp_version]
# Print a human-readable summary: total count, channels, latest bundle, and related images.
# Accepts either an OKD directory name (e.g. "sr-iov") or RH package name.
# Pass an OCP version (e.g. "4.21") to filter to that release.
operator_summary() {
  local -r arg="${1:?Usage: operator_summary <package-or-dir> [ocp_version]}"
  local ocp_version="${2:-}"
  local package
  package=$(okd_to_package "$arg")

  echo "=== ${package} ==="
  echo ""

  # Get total count
  local total_resp
  total_resp=$(get_bundles "$package" "$ocp_version" 1)
  local total
  total=$(echo "$total_resp" | jq '.data.find_operator_bundles.total')
  echo "Total bundles in catalog${ocp_version:+ (ocp_version=${ocp_version})}: ${total}"
  echo ""

  # Fetch recent bundles for channel listing (filtered by ocp_version if given)
  local recent_bundles
  recent_bundles=$(get_bundles "$package" "$ocp_version" 50)

  echo "Channels (from most recent 50 matching bundles):"
  echo "$recent_bundles" | jq -r '.data.find_operator_bundles.data[].channel_name' | sort -u \
    | while IFS= read -r ch; do
        local latest
        latest=$(echo "$recent_bundles" | jq -r --arg ch "$ch" \
          '[.data.find_operator_bundles.data[] | select(.channel_name == $ch) | .version] | first')
        printf "  %-24s (latest: %s)\n" "$ch" "$latest"
      done
  echo ""

  local latest_bundle
  latest_bundle=$(echo "$recent_bundles" | jq '.data.find_operator_bundles.data[0]')

  local bundle_ver bundle_path bundle_ocp
  bundle_ver=$(echo "$latest_bundle" | jq -r '.version')
  bundle_path=$(echo "$latest_bundle" | jq -r '.bundle_path')
  bundle_ocp=$(echo "$latest_bundle" | jq -r '.ocp_version')

  echo "Most recent bundle: ${bundle_ver} (ocp_version: ${bundle_ocp})"
  echo "  Path: ${bundle_path}"
  echo ""

  echo "Related images:"
  echo "$latest_bundle" | jq -r '.related_images[] | select(.name != "") | "  \(.name)\n    \(.image)"'
}

usage() {
  cat <<'EOF'
Usage: rhcatalog.sh <command> [args]

Commands:
  find-operators <pattern>                 Find operator packages matching pattern
  bundles <package> [ocp_ver]             List bundles for a package (JSON output)
  bundle-images <package> [ocp_ver]       Show related images from latest bundle
  image-labels <image-id>                 Show labels/env vars for an image (MongoDB ID)
  image-layers <image-id>                 Show layer info for an image
  image-files <image-id> [page_size]      List files within an image
  find-repos <pattern>                    Find repositories matching pattern
  repo-images <registry> <repo>           List images in a repository
  compare <package> <ocp_ver1> <ocp_ver2> Diff component images between two OCP versions
  summary <package-or-dir> [ocp_ver]      Full summary for an operator
  containerfiles <package-or-dir> [ocp_ver] Fetch Dockerfiles for all component images
  dump-containerfiles <pkg> <tag> <dir>   Write each component Dockerfile to a file in dir
  find-by-tag <repo-path> <tag>           Find image by exact tag, show catalog entry
  list-tags <repo-path> [pattern]         List human-readable tags for a repository
  containerfile-by-tag <repo-path> <tag>  Get Dockerfile for a specific tag

OKD directory names are automatically resolved to RH package names (e.g. "sr-iov" -> "sriov-network-operator").
The script can also be sourced to call functions individually.

Environment:
  GRAPHQL_URL   Override the GraphQL endpoint (default: https://catalog.redhat.com/api/containers/graphql/)

Examples:
  ./scripts/rhcatalog.sh find-operators metallb
  ./scripts/rhcatalog.sh bundle-images metallb-operator 4.21
  ./scripts/rhcatalog.sh compare sriov-network-operator 4.20 4.21
  ./scripts/rhcatalog.sh summary sr-iov 4.21
  ./scripts/rhcatalog.sh containerfiles sr-iov 4.21
  ./scripts/rhcatalog.sh dump-containerfiles metallb v4.21.0 ./out/metallb/
  ./scripts/rhcatalog.sh list-tags openshift4/metallb-rhel9-operator v4.21
  ./scripts/rhcatalog.sh containerfile-by-tag openshift4/metallb-rhel9-operator v4.21.0
  source scripts/rhcatalog.sh && get_bundle_images metallb-operator 4.21
EOF
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  local -r cmd="$1"
  shift

  case "$cmd" in
    find-operators) find_operators "$@" ;;
    bundles)        get_bundles "$@" | jq '.data.find_operator_bundles' ;;
    bundle-images)  get_bundle_images "$@" ;;
    image-labels)   get_image_labels "$@" ;;
    image-layers)   get_image_layers "$@" ;;
    image-files)    get_image_files "$@" ;;
    find-repos)     find_repos "$@" ;;
    repo-images)    get_repo_images "$@" ;;
    compare)          compare_versions "$@" ;;
    summary)          operator_summary "$@" ;;
    containerfiles)        get_operator_containerfiles "$@" ;;
    dump-containerfiles)   dump_operator_containerfiles "$@" ;;
    find-by-tag)           find_image_by_tag "$@" ;;
    list-tags)             list_repo_tags "$@" ;;
    containerfile-by-tag)  get_containerfile_by_tag "$@" ;;
    help|--help|-h) usage ;;
    *)
      echo "Unknown command: ${cmd}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  main "$@"
fi
