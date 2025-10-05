#!/bin/bash

NAMESPACE="cert-manager"

MAJOR=1
MINOR=18

source ../common.sh

submodule_update cert-manager release-${OCP_SHORT} https://github.com/openshift/jetstack-cert-manager.git
submodule_update istio-csr main https://github.com/openshift/cert-manager-istio-csr.git
submodule_update operator cert-manager-${OCP_SHORT} https://github.com/openshift/cert-manager-operator.git