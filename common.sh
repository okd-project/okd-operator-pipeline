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