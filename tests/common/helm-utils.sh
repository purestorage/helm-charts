#!/usr/bin/env bash

# Copyright 2017, Pure Storage Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

HELM_CHARTS_REPO_URL_DEFAULT=https://purestorage.github.io/helm-charts
HELM_CHARTS_REPO_NAME_DEFAULT=pure

function init_helm {
    local chart_repo_url=${1:-${HELM_CHARTS_REPO_URL_DEFAULT}}
    local chart_repo_name=${2:-${HELM_CHARTS_REPO_NAME_DEFAULT}}
    helm init
    local n=0
    while true; do
        [ $n -lt ${CHECK_LIMIT} ]
        n=$[$n+1]
        sleep ${CHECK_INTERVAL}
        local readyTillers=$(kubectl get rs -l name=tiller -n kube-system -o json | jq -r '.items[].status.readyReplicas')
        [[ ${readyTillers} == [0-9]* ]] || continue
        [ ${readyTillers} -gt 0 ] && break
    done
    # test if helm is working
    helm list
    helm repo add ${chart_repo_name} ${chart_repo_url}
    helm repo update
}
