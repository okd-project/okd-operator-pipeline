#!/bin/bash

NAMESPACE="lvms"

source ../common.sh

submodule_update operator release-${OCP_SHORT} https://github.com/openshift/lvm-operator.git