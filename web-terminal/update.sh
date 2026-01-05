#!/bin/bash

source version.sh
source ../common.sh

submodule_update operator wto-${OCP_SHORT} https://github.com/redhat-developer/web-terminal-operator.git
submodule_update tooling main https://github.com/redhat-developer/web-terminal-tooling.git
submodule_update exec main https://github.com/redhat-developer/web-terminal-exec.git