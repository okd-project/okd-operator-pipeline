#!/bin/bash

NAMESPACE="local-storage"

source ../common.sh

submodule_update operator release-${OCP_SHORT} https://github.com/openshift/local-storage-operator.git