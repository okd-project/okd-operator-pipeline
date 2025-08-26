#!/usr/bin/env bash

function update_submodule() {
  local submodule_path="$1"
  local submodule_branch="$2"

  if [ -d "$submodule_path" ]; then
    git_url=$(git -C "$submodule_path" remote get-url origin)
    echo "Updating submodule: $git_url"
    git -C "$submodule_path" fetch origin "$submodule_branch"
    git -C "$submodule_path" reset --hard "origin/$submodule_branch"
    git -C "$submodule_path" submodule update --init
  else
    echo "Submodule path $submodule_path does not exist."
  fi
}

ACM_BRANCH="release-2.15"
FLIGHTCTL_BRANCH="release-0.8"
SUBMARINER_BRANCH="release-0.21"

update_submodule acm-cli $ACM_BRANCH
update_submodule cert-policy-controller $ACM_BRANCH
update_submodule cluster-backup-operator $ACM_BRANCH
update_submodule cluster-permission $ACM_BRANCH
update_submodule config-policy-controller $ACM_BRANCH
update_submodule console $ACM_BRANCH
update_submodule flightctl $FLIGHTCTL_BRANCH
update_submodule flightctl-ui $FLIGHTCTL_BRANCH
update_submodule governance-policy-addon-controller $ACM_BRANCH
update_submodule governance-policy-framework-addon $ACM_BRANCH
update_submodule governance-policy-propagator $ACM_BRANCH
update_submodule grafana $ACM_BRANCH
update_submodule insights-client $ACM_BRANCH
update_submodule insights-metrics $ACM_BRANCH
update_submodule klusterlet-addon-controller $ACM_BRANCH
update_submodule kube-state-metrics $ACM_BRANCH
update_submodule lighthouse $SUBMARINER_BRANCH
update_submodule memcached_exporter $ACM_BRANCH
update_submodule multicloud-integrations $ACM_BRANCH
update_submodule multicloud-operators-application $ACM_BRANCH
update_submodule multicloud-operators-subscription $ACM_BRANCH
update_submodule multicluster-observability-addon $ACM_BRANCH
update_submodule multicluster-observability-operator $ACM_BRANCH
update_submodule multiclusterhub-operator $ACM_BRANCH
update_submodule must-gather $ACM_BRANCH
update_submodule node-exporter $ACM_BRANCH
update_submodule observatorium-operator $ACM_BRANCH
update_submodule observatorium $ACM_BRANCH
update_submodule prometheus $ACM_BRANCH
update_submodule prometheus-alertmanager $ACM_BRANCH
update_submodule prometheus-operator $ACM_BRANCH
update_submodule search-collector $ACM_BRANCH
update_submodule search-indexer $ACM_BRANCH
update_submodule search-v2-api $ACM_BRANCH
update_submodule search-v2-operator $ACM_BRANCH
update_submodule shipyard $SUBMARINER_BRANCH
update_submodule siteconfig $ACM_BRANCH
update_submodule subctl $SUBMARINER_BRANCH
update_submodule submariner $SUBMARINER_BRANCH
update_submodule submariner-addon $ACM_BRANCH
update_submodule submariner-operator $SUBMARINER_BRANCH
update_submodule thanos $ACM_BRANCH
update_submodule thanos-recieve-controller $ACM_BRANCH
update_submodule volsync release-0.13
update_submodule volsync-addon-controller $ACM_BRANCH
