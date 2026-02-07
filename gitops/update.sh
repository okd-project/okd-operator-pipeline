#!/bin/bash

source version.sh
source ../common.sh

submodule_update release release-${OCP_SHORT} https://github.com/rh-gitops-midstream/release.git