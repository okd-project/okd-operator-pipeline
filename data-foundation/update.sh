#!/bin/bash

NAMESPACE="data-foundation"

source ../common.sh

submodule_update ceph-csi release-v3.15 https://github.com/ceph/ceph-csi.git
submodule_update ceph-csi-operator release-${OCP_SHORT} https://github.com/red-hat-storage/ceph-csi-operator.git
submodule_update cloudnative-pg rhodf-${OCP_SHORT} https://github.com/red-hat-storage/cloudnative-pg.git
submodule_update container-object-storage-interface-provisioner-sidecar master https://github.com/kubernetes-retired/container-object-storage-interface-provisioner-sidecar.git
submodule_update kubernetes-csi-addons release-${OCP_SHORT} https://github.com/red-hat-storage/kubernetes-csi-addons.git
submodule_update must-gather release-${OCP_SHORT} https://github.com/red-hat-storage/odf-must-gather.git
submodule_update noobaa-core release-${OCP_SHORT} https://github.com/red-hat-storage/noobaa-core.git
submodule_update noobaa-operator release-${OCP_SHORT} https://github.com/red-hat-storage/noobaa-operator.git
submodule_update ocs-client-operator release-${OCP_SHORT} https://github.com/red-hat-storage/ocs-client-operator.git
submodule_update ocs-operator release-${OCP_SHORT} https://github.com/red-hat-storage/ocs-operator.git
submodule_update odf-cli release-${OCP_SHORT} https://github.com/red-hat-storage/odf-cli.git
submodule_update odf-console release-${OCP_SHORT} https://github.com/red-hat-storage/odf-console.git
submodule_update odf-console-compatibility release-${OCP_SHORT}-compatibility https://github.com/red-hat-storage/odf-console.git
submodule_update odf-multicluster-orchestrator release-${OCP_SHORT} https://github.com/red-hat-storage/odf-multicluster-orchestrator.git
submodule_update odf-operator release-${OCP_SHORT} https://github.com/red-hat-storage/odf-operator.git
submodule_update ramen release-${OCP_SHORT} https://github.com/red-hat-storage/ramen.git
submodule_update recipe release-${OCP_SHORT} https://github.com/red-hat-storage/recipe.git
submodule_update rook release-${OCP_SHORT} https://github.com/red-hat-storage/rook.git
