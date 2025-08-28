#!/bin/bash

NAMESPACE="ingress-node-firewall"

source ../common.sh

submodule_update operator release-${OCP_SHORT} https://github.com/openshift/ingress-node-firewall.git