#!/bin/bash

NAMESPACE="cert-manager"
MAJOR=1
MINOR=15

source ../common.sh

IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_CERT_MANAGER="${REGISTRY}/cert-manager:${OCP_DATE}"
IMG_ACME_SOLVER="${REGISTRY}/acme-solver:${OCP_DATE}"
IMG_ISTIO_CSR="${REGISTRY}/istio-csr:${OCP_DATE}"

IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

apply_patch operator cert-manager-${OCP_SHORT}

# Build the images
podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .
podman build -t "${IMG_CERT_MANAGER}" -f cert-manager.Containerfile .
podman build -t "${IMG_ACME_SOLVER}" -f acme-solver.Containerfile .
podman build -t "${IMG_ISTIO_CSR}" -f istio-csr.Containerfile .

# Push the images
podman push "${IMG_OPERATOR}"
podman push "${IMG_CERT_MANAGER}"
podman push "${IMG_ACME_SOLVER}"
podman push "${IMG_ISTIO_CSR}"

pushd operator

yq e -i "with((select(.kind == \"Deployment\") | .spec.template.spec.containers[0]) ;
 .env |= map(select(.name == \"RELATED_IMAGE_CERT_MANAGER_WEBHOOK\").value = \"${IMG_CERT_MANAGER}\") |
 .env |= map(select(.name == \"RELATED_IMAGE_CERT_MANAGER_CA_INJECTOR\").value = \"${IMG_CERT_MANAGER}\") |
 .env |= map(select(.name == \"RELATED_IMAGE_CERT_MANAGER_CONTROLLER\").value = \"${IMG_CERT_MANAGER}\") |
 .env |= map(select(.name == \"RELATED_IMAGE_CERT_MANAGER_ACMESOLVER\").value = \"${IMG_ACME_SOLVER}\") |
 .env |= map(select(.name == \"RELATED_IMAGE_CERT_MANAGER_ISTIOCSR\").value = \"${IMG_ISTIO_CSR}\") |
 .env |= map(select(.name == \"OPERAND_IMAGE_VERSION\").value = \"${OCP_DATE}\") |
 .env |= map(select(.name == \"ISTIOCSR_OPERAND_IMAGE_VERSION\").value = \"${OCP_DATE}\") |
 .env |= map(select(.name == \"OPERATOR_IMAGE_VERSION\").value = \"${OCP_DATE}\")
)" ./config/manager/manager.yaml

make bundle BUNDLE_VERSION=${OCP_DATE} IMG=${IMG_OPERATOR} "BUNDLE_METADATA_OPTS=${BUNDLE_METADATA_OPTS}" \
 BUNDLE_IMG=${IMG_BUNDLE} CONTAINER_ENGINE=podman ISTIO_CSR_VERSION=${OCP_DATE}

podman build -f bundle.Dockerfile -t "${IMG_BUNDLE}" .
podman push "${IMG_BUNDLE}"

popd


