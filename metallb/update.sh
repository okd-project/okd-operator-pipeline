#!/bin/bash

NAMESPACE="metallb"

source ../common.sh

submodule_update frr release-${OCP_SHORT} https://github.com/openshift/frr.git
submodule_update metallb release-${OCP_SHORT} https://github.com/openshift/metallb.git
submodule_update operator release-${OCP_SHORT} https://github.com/openshift/metallb-operator.git
