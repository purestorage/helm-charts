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

set -xe

# This script is to test the upgrade from the latest GA version to the current developing one 
WORKSPACE=${WORKSPACE:-$(dirname $0)/..}

KUBECONFIG=${WORKSPACE}/kube.conf
HELM_HOME=${WORKSPACE}/.helm
VM_DRIVER=${MINIKUBE_VM_DRIVER:-virtualbox}
MINIKUBE_NAME=helm-chart-upgrade-test

CHECK_LIMIT=30
CHECK_INTERVAL=10

DELETE_MINIKUBE=true

function verify_helm_install {
    # verify for pure-provisioner
    local imageInstalled=$(kubectl get deploy pure-provisioner -o json | jq -r '.spec.template.spec.containers[].image')
    [ "${imageInstalled}" == "purestorage/k8s:${IMAGE_TAG}" ]

    local desiredProvisioner=1
    local n=0
    while true; do
        [ $n -lt ${CHECK_LIMIT} ]
        n=$[$n+1]
        sleep ${CHECK_INTERVAL}
        local readyProvisioner=$(kubectl get deploy pure-provisioner -o json | jq -r '.status.readyReplicas')
        [ "${readyProvisioner}" == "${desiredProvisioner}" ] && break
    done

    # verify for pure-flex
    local imageInstalled=$(kubectl get ds pure-flex -o json | jq -r '.spec.template.spec.containers[].image')
    [ "${imageInstalled}" == "purestorage/k8s:${IMAGE_TAG}" ]

    local desiredFlexes=$(kubectl get ds pure-flex -o json | jq -r '.status.desiredNumberScheduled')
    n=0
    while true; do
        [ $n -lt ${CHECK_LIMIT} ]
        n=$[$n+1]
        sleep ${CHECK_INTERVAL}
        local readyFlexes=$(kubectl get ds pure-flex -o json | jq -r '.status.numberReady')
        [ "${readyFlexes}" == "${desiredFlexes}" ] && break
    done
}

function init_helm {
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
    helm repo add pure https://purestorage.github.io/helm-charts
    helm repo update
}

function start_minikube {
    if [ "${VM_DRIVER}" == "none" ]; then
        if pgrep kubelet; then
            echo "Found an exisitng minikube. Please have a check. Stop and delete it carefully before retry"
            DELETE_MINIKUBE=false
            false
        fi
    else
        if minikube status -p ${MINIKUBE_NAME}; then
            echo "Found an exisitng minikube(${MINIKUBE_NAME}). Please have a check. Stop and delete it carefully before retry"
            DELETE_MINIKUBE=false
            false
        fi
    fi

    echo "Starting a minikube for testing ..."
    # start a minikube for test
    minikube start --vm-driver ${VM_DRIVER} -p ${MINIKUBE_NAME}
    # verify minikube
    local n=0
    while true; do
        [ $n -lt ${CHECK_LIMIT} ]
        n=$[$n+1]
        sleep ${CHECK_INTERVAL}
        kubectl get pods --all-namespaces | grep kube-system | grep -v Running || break
    done
}

function final_steps() {
    if ${DELETE_MINIKUBE}; then
        minikube stop -p ${MINIKUBE_NAME} || echo "Warning: failed to stop the minikube(${MINIKUBE_NAME})"
        minikube delete -p ${MINIKUBE_NAME}
    fi
    rm -rf ${KUBECONFIG} ${HELM_HOME}
}
trap final_steps EXIT


start_minikube

init_helm

CHART_VERSION_LIST=$(helm search pure/pure-k8s-plugin -l | grep pure-k8s-plugin | awk '{print $2}')
LATEST_CHART_VERSION=$(helm search pure/pure-k8s-plugin | grep pure-k8s-plugin | awk '{print $2}')
IMAGE_TAG=${PRE_CHART_VERSION:-latest}
isValidVersion=0
if [ "${IMAGE_TAG}" == "latest" ]; then
    IMAGE_TAG=${LATEST_CHART_VERSION}
else
    for v in ${CHART_VERSION_LIST}; do
        if [ "$v" == ${IMAGE_TAG} ]; then
            isValidVersion=1
            break
        fi
    done
    if [ $isValidVersion -ne 1 ]; then
        echo "Failure: Invalid chart version ${IMAGE_TAG}"
        false
    fi
fi

echo "Installing the plugin ..."
# for testing upgrade only, set arrays to empty
helm install -n pure pure/pure-k8s-plugin --version ${IMAGE_TAG} --set arrays=""

echo "Verifying the installation ..."
verify_helm_install
kubectl get all -o wide

echo "Upgrading the plugin ..."
IMAGE_TAG=$(grep ' tag:' ${WORKSPACE}/pure-k8s-plugin/values.yaml | cut -d':' -f2 | tr -d ' ')
helm upgrade pure ${WORKSPACE}/pure-k8s-plugin --set arrays=""

echo "Verifying the upgrade ..."
verify_helm_install
kubectl get all -o wide

helm history pure