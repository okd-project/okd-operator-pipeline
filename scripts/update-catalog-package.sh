#!/bin/bash
#
# Update (or create) the OLM package YAML of a file-based catalog so that a
# newly rendered bundle is wired into the channel upgrade graph. This is the
# companion to okderators-catalog-index's hack/add-bundle.sh, which renders
# the bundle file but does not touch the olm.package/olm.channel documents.
#
# Usage: update-catalog-package.sh <package-file> <bundle-name> [channel]
#   package-file  catalog/<operator>/<operator>.yaml (inside the catalog repo)
#   bundle-name   CSV name, e.g. cert-manager-operator.v1.18.0-2025-12-25-214537
#   channel       channel used when the package file does not exist yet;
#                 existing files use their defaultChannel (default: alpha)
#
# Requires: yq (v4+)

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <package-file> <bundle-name> [channel]"
  exit 1
fi

PKG_FILE=$1
export BUNDLE_NAME=$2
export CHANNEL=${3:-alpha}
OPERATOR=$(basename "$PKG_FILE" .yaml)

if [ ! -f "$PKG_FILE" ]; then
  echo "Creating package file ${PKG_FILE} (defaultChannel: ${CHANNEL})"
  mkdir -p "$(dirname "$PKG_FILE")"
  cat > "$PKG_FILE" <<EOF
---
schema: olm.package
name: ${OPERATOR}
defaultChannel: ${CHANNEL}
---
schema: olm.channel
package: ${OPERATOR}
name: ${CHANNEL}
entries:
  - name: ${BUNDLE_NAME}
EOF
  exit 0
fi

# Existing package: wire the bundle into the default channel
DEFAULT_CHANNEL=$(yq 'select(.schema == "olm.package") | .defaultChannel' "$PKG_FILE")
if [ -n "$DEFAULT_CHANNEL" ] && [ "$DEFAULT_CHANNEL" != "null" ]; then
  CHANNEL=$DEFAULT_CHANNEL
fi
export CHANNEL

# Channel document missing entirely: append a fresh one
if [ -z "$(yq 'select(.schema == "olm.channel" and .name == env(CHANNEL)) | .name' "$PKG_FILE")" ]; then
  echo "Adding channel ${CHANNEL} with entry ${BUNDLE_NAME} to ${PKG_FILE}"
  cat >> "$PKG_FILE" <<EOF
---
schema: olm.channel
package: ${OPERATOR}
name: ${CHANNEL}
entries:
  - name: ${BUNDLE_NAME}
EOF
  exit 0
fi

# Entry already present: nothing to do
if [ -n "$(yq 'select(.schema == "olm.channel" and .name == env(CHANNEL)) | .entries[] | select(.name == env(BUNDLE_NAME)) | .name' "$PKG_FILE")" ]; then
  echo "${BUNDLE_NAME} is already in channel ${CHANNEL} of ${PKG_FILE}; skipping"
  exit 0
fi

PREVIOUS=$(yq 'select(.schema == "olm.channel" and .name == env(CHANNEL)) | .entries[-1].name' "$PKG_FILE")
export PREVIOUS

# yq -i re-emits the file without a leading document separator; remember
# whether one was there so the diff stays clean
HAD_LEADING_SEPARATOR=0
[ "$(head -n 1 "$PKG_FILE")" = "---" ] && HAD_LEADING_SEPARATOR=1

yq -i '(select(.schema == "olm.channel" and .name == env(CHANNEL)) | .entries) += [{"name": env(BUNDLE_NAME), "replaces": env(PREVIOUS)}]' "$PKG_FILE"

if [ "$HAD_LEADING_SEPARATOR" = "1" ] && [ "$(head -n 1 "$PKG_FILE")" != "---" ]; then
  sed -i '1i ---' "$PKG_FILE"
fi

echo "Appended ${BUNDLE_NAME} (replaces ${PREVIOUS}) to channel ${CHANNEL} in ${PKG_FILE}"
