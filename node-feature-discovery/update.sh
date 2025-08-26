#!/bin/bash

NAMESPACE="sr-iov"

source ../common.sh

submodule_update nfd release-${OCP_SHORT} https://github.com/openshift/node-feature-discovery.git
submodule_update operator release-${OCP_SHORT} https://github.com/openshift/cluster-nfd-operator.git