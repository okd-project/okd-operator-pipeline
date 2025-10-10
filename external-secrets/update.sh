#!/bin/bash

NAMESPACE="ingress-node-firewall"

MAJOR=1
MINOR=0

ES_RELEASE="0.19"
BITWARDEN_SDK_RELEASE="0.5.1"

source ../common.sh

submodule_update operator release-${OCP_SHORT} https://github.com/openshift/external-secrets-operator.git
submodule_update external-secrets release-${ES_RELEASE} https://github.com/openshift/external-secrets.git
submodule_update bitwarden-sdk-server release-${BITWARDEN_SDK_RELEASE} https://github.com/openshift/external-secrets-bitwarden-sdk-server.git