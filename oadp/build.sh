#!/bin/bash

NAMESPACE="oadp"

source version.sh
source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_VELERO="${REGISTRY}/velero:${OCP_DATE}"
export IMG_AWS_PLUGIN="${REGISTRY}/aws-plugin:${OCP_DATE}"
export IMG_AZURE_PLUGIN="${REGISTRY}/azure-plugin:${OCP_DATE}"
export IMG_GCP_PLUGIN="${REGISTRY}/gcp-plugin:${OCP_DATE}"
export IMG_MUST_GATHER="${REGISTRY}/must-gather:${OCP_DATE}"
export IMG_OPENSHIFT_PLUGIN="${REGISTRY}/openshift-plugin:${OCP_DATE}"
export IMG_NON_ADMIN="${REGISTRY}/non-admin:${OCP_DATE}"
export IMG_HYPERSHIFT_PLUGIN="${REGISTRY}/hypershift-plugin:${OCP_DATE}"
export IMG_AWS_LEGACY_PLUGIN="${REGISTRY}/aws-legacy-plugin:${OCP_DATE}"
export IMG_KUBEVIRT_PLUGIN="${REGISTRY}/kubevirt-plugin:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/bundle:${OCP_DATE}"

submodule_initialize operator oadp-${OCP_SHORT}
submodule_initialize velero oadp-${OCP_SHORT}
submodule_initialize aws-plugin oadp-${OCP_SHORT}
submodule_initialize microsoft-azure-plugin oadp-${OCP_SHORT}
submodule_initialize openshift-plugin oadp-${OCP_SHORT}
submodule_initialize hypershift-plugin oadp-${OCP_SHORT}
submodule_initialize non-admin oadp-${OCP_SHORT}
submodule_initialize gcp-plugin oadp-${OCP_SHORT}
submodule_initialize aws-legacy-plugin oadp-${OCP_SHORT}
submodule_initialize kubevirt-plugin release-v0.8

podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_VELERO -f velero.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_OPERATOR -f operator.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_AWS_PLUGIN -f aws-plugin.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_AZURE_PLUGIN -f microsoft-azure-plugin.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_GCP_PLUGIN -f gcp-plugin.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_OPENSHIFT_PLUGIN -f openshift-plugin.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_NON_ADMIN -f non-admin.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_HYPERSHIFT_PLUGIN -f hypershift-plugin.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_AWS_LEGACY_PLUGIN -f aws-legacy-plugin.Containerfile .
podman build --build-arg CI_VERSION=${OCP_DATE} -t $IMG_KUBEVIRT_PLUGIN -f kubevirt-plugin.Containerfile .
podman build --build-arg VELERO_IMG=$IMG_VELERO -t $IMG_MUST_GATHER -f must-gather.Containerfile .