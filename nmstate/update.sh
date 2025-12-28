#!/bin/bash

source version.sh
source ../common.sh

submodule_update operator release-${OCP_SHORT} https://github.com/openshift/kubernetes-nmstate.git
submodule_update console-plugin release-${OCP_SHORT} https://github.com/openshift/nmstate-console-plugin.git