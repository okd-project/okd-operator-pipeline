#!/bin/bash

NAMESPACE="sr-iov"

source ../common.sh

submodule_update admission-controller release-${OCP_SHORT} https://github.com/openshift/sriov-dp-admission-controller.git
submodule_update cni release-${OCP_SHORT} https://github.com/openshift/sriov-cni.git
submodule_update device-plugin release-${OCP_SHORT} https://github.com/openshift/sriov-network-device-plugin.git
submodule_update infiniband-cni release-${OCP_SHORT} https://github.com/openshift/ib-sriov-cni.git
submodule_update metrics-exporter release-${OCP_SHORT} https://github.com/openshift/sriov-network-metrics-exporter.git
submodule_update operator release-${OCP_SHORT} https://github.com/openshift/sriov-network-operator.git
submodule_update rdma-cni release-${OCP_SHORT} https://github.com/openshift/rdma-cni.git