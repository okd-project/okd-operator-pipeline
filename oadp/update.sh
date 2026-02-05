#!/bin/bash

source version.sh
source ../common.sh

BRANCH="oadp-${OCP_SHORT}"
KUBEVIRT_BRANCH="release-v${KUBEVIRT_PLUGIN_RELEASE}"

submodule_update velero ${BRANCH} https://github.com/openshift/velero.git
submodule_update operator ${BRANCH} https://github.com/openshift/oadp-operator.git
submodule_update non-admin ${BRANCH} https://github.com/migtools/oadp-non-admin.git
submodule_update microsoft-azure-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-microsoft-azure.git
submodule_update openshift-plugin ${BRANCH} https://github.com/openshift/openshift-velero-plugin.git
submodule_update hypershift-plugin ${BRANCH} https://github.com/openshift/hypershift-oadp-plugin.git
submodule_update aws-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-aws.git
submodule_update aws-legacy-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-legacy-aws.git
submodule_update gcp-plugin ${BRANCH} https://github.com/openshift/velero-plugin-for-gcp.git
submodule_update kubevirt-plugin ${KUBEVIRT_BRANCH} https://github.com/migtools/kubevirt-velero-plugin.git
submodule_update kopia ${BRANCH} https://github.com/migtools/kopia.git
submodule_update restic ${BRANCH} https://github.com/openshift/restic.git