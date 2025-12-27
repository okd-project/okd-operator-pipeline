#!/bin/bash

source version.sh
source ../common.sh

submodule_update operator release-${OCP_SHORT} https://github.com/netobserv/network-observability-operator.git
submodule_update console-plugin release-${OCP_SHORT} https://github.com/netobserv/network-observability-console-plugin.git
submodule_update console-plugin-compat release-${OCP_SHORT}-pf4 https://github.com/netobserv/network-observability-console-plugin.git
submodule_update flowlogs-pipeline release-${OCP_SHORT} https://github.com/netobserv/flowlogs-pipeline.git
submodule_update cli release-${OCP_SHORT} https://github.com/netobserv/network-observability-cli.git
submodule_update ebpf-agent release-${OCP_SHORT} https://github.com/netobserv/netobserv-ebpf-agent.git