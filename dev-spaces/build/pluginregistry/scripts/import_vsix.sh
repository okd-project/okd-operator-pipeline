#!/bin/bash
# Import pre-installed VSIX files into the OpenVSX registry.
# On first run the registry database is empty; this script imports any .vsix
# files placed in /openvsx-server/vsix/ before the server starts.

set -euo pipefail

VSIX_DIR="${VSIX_DIR:-/openvsx-server/vsix}"
OPENVSX_SERVER="${OPENVSX_SERVER:-http://localhost:8080}"

if [[ ! -d "${VSIX_DIR}" ]] || [[ -z "$(ls -A "${VSIX_DIR}" 2>/dev/null)" ]]; then
    echo "No VSIX files found in ${VSIX_DIR}, skipping import."
    exit 0
fi

for vsix in "${VSIX_DIR}"/*.vsix; do
    echo "Importing ${vsix}..."
    ovsx publish "${vsix}" --registryUrl "${OPENVSX_SERVER}" --pat local-token || true
done
