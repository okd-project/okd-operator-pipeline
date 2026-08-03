#!/bin/bash
#
# Build the Kata Containers RPM in Fedora COPR for OKD's Sandboxed Containers operator.
#
# The sandboxed-containers operator installs the Kata runtime on SCOS nodes by
# emitting a MachineConfig that requests the "kata-containers" rpm-ostree extension.
# rpm-ostree can only satisfy that extension if the kata-containers RPM is published
# in a repo the node can reach; this script builds that RPM in COPR.
#
# The COPR chroot MUST match the SCOS base OS of the target OKD release:
#   OKD 4.20+  ->  CentOS Stream 10  ->  centos-stream-10-<arch>
# (Older SCOS releases were CentOS Stream 9 -> centos-stream-9-<arch>.)
#
# Requires: copr-cli, and a Fedora account token at ~/.config/copr
# (get one from https://copr.fedorainfracloud.org/api/).
#
# Usage:
#   ./copr-build.sh
# All inputs are environment variables with defaults (override as needed):

set -euo pipefail

# --- Configuration -----------------------------------------------------------

# COPR owner (a username, or "@group" for a group project) and project name.
# The resulting public repo will be:
#   https://download.copr.fedorainfracloud.org/results/${COPR_OWNER}/${COPR_PROJECT}/
COPR_OWNER="${COPR_OWNER:-okderators}"
COPR_PROJECT="${COPR_PROJECT:-sandboxed-containers-kata}"

# Space-separated list of build targets. Must track the SCOS base OS (see above).
# SCOS is x86_64/aarch64; add other arches only if your SCOS build supports them.
CHROOTS="${CHROOTS:-centos-stream-10-x86_64 centos-stream-10-aarch64}"

# Source of the kata-containers spec. Defaults to Fedora dist-git (rawhide), which
# carries kata-containers.spec + a lookaside "sources" file (handled by the rpkg
# method). Point this at the CentOS Stream / Virt SIG dist-git instead if you need
# a spec pinned to the SCOS package set.
KATA_CLONE_URL="${KATA_CLONE_URL:-https://src.fedoraproject.org/rpms/kata-containers.git}"
KATA_COMMITTISH="${KATA_COMMITTISH:-rawhide}"
KATA_SUBDIR="${KATA_SUBDIR:-.}"
KATA_SPEC="${KATA_SPEC:-kata-containers.spec}"
KATA_SCM_METHOD="${KATA_SCM_METHOD:-rpkg}"

# Alternatively, build straight from a prebuilt SRPM (URL or local path). If set,
# this takes precedence over the SCM build above.
KATA_SRPM="${KATA_SRPM:-}"

# Set COPR_NOWAIT=1 to submit the build and return immediately instead of blocking.
COPR_NOWAIT="${COPR_NOWAIT:-}"

# --- Derived -----------------------------------------------------------------

PROJECT_REF="${COPR_OWNER}/${COPR_PROJECT}"

CHROOT_ARGS=()
for c in ${CHROOTS}; do
  CHROOT_ARGS+=(--chroot "${c}")
done

WAIT_ARGS=()
[ -n "${COPR_NOWAIT}" ] && WAIT_ARGS+=(--nowait)

command -v copr-cli >/dev/null 2>&1 || { echo "ERROR: copr-cli not found on PATH." >&2; exit 1; }

# --- Ensure the project exists with the right chroots ------------------------

echo ">> Ensuring COPR project ${PROJECT_REF} exists with chroots: ${CHROOTS}"
if ! copr-cli create "${PROJECT_REF}" \
      "${CHROOT_ARGS[@]}" \
      --description "Kata Containers RPM for OKD sandboxed-containers (SCOS rpm-ostree extension)" \
      --instructions "Consumed by the openshift-sandboxed-containers operator on OKD/SCOS. See sandboxed-containers/copr/README.md in okd-operator-pipeline." \
      2>/dev/null; then
  echo ">> Project already exists (or create is a no-op); ensuring chroots are enabled."
  copr-cli modify "${PROJECT_REF}" "${CHROOT_ARGS[@]}"
fi

# --- Submit the build --------------------------------------------------------

if [ -n "${KATA_SRPM}" ]; then
  echo ">> Building from SRPM: ${KATA_SRPM}"
  copr-cli build "${WAIT_ARGS[@]}" "${PROJECT_REF}" "${KATA_SRPM}"
else
  echo ">> Building from SCM: ${KATA_CLONE_URL}@${KATA_COMMITTISH} (spec: ${KATA_SPEC}, method: ${KATA_SCM_METHOD})"
  copr-cli buildscm "${WAIT_ARGS[@]}" "${PROJECT_REF}" \
    --clone-url "${KATA_CLONE_URL}" \
    --commit "${KATA_COMMITTISH}" \
    --subdir "${KATA_SUBDIR}" \
    --spec "${KATA_SPEC}" \
    --method "${KATA_SCM_METHOD}"
fi

echo
echo ">> Done. Resulting repo (once the build succeeds):"
for c in ${CHROOTS}; do
  echo "   https://download.copr.fedorainfracloud.org/results/${COPR_OWNER}/${COPR_PROJECT}/${c}/"
done
