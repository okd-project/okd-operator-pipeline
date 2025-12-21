#!/bin/bash

NAMESPACE="pf-status-relay"

source ../common.sh

submodule_update operator release-${OCP_SHORT} https://github.com/openshift/pf-status-relay-operator.git
submodule_update relay release-${OCP_SHORT} https://github.com/openshift/pf-status-relay.git