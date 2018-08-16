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

CHECK_LIMIT=30
CHECK_INTERVAL=10

function start_minikube {
    local minikube_instance_name=$1
    if [ "${minikube_instance_name}" == "" ]; then
        echo "Must provide a minikube instance name to create"
        return 1
    fi
    local instance=$(echo ${minikube_instance_name} | sed 's/-/_/g')
    eval _minikube_vm_driver_$instance=${2:-virtualbox}
    eval _delete_minikube_$instance=true
    if eval [ "\${_minikube_vm_driver_$instance}" == "none" ]; then
        if pgrep kubelet; then
            echo "Found an exisitng minikube. Please have a check. Stop and delete it carefully before retry"
            # when exit, don't delete the minikube
            eval _delete_minikube_$instance=false
            return 1
        fi
    else
        if minikube status -p ${minikube_instance_name}; then
            echo "Found an exisitng minikube(${minikube_instance_name}). Please have a check. Stop and delete it carefully before retry"
            # when exit, don't delete the minikube
            eval _delete_minikube_$instance=false
            return 1
        fi
    fi

    echo "Starting a minikube(${minikube_instance_name}) for testing ..."
    # start a minikube for test
    eval minikube start --vm-driver \${_minikube_vm_driver_$instance} -p ${minikube_instance_name}
    # verify minikube
    local n=0
    while true; do
        [ $n -lt ${CHECK_LIMIT} ]
        n=$[$n+1]
        sleep ${CHECK_INTERVAL}
        kubectl get pods --all-namespaces | grep kube-system | grep -v Running || break
    done
}

function cleanup_minikube() {
    local minikube_instance_name=$1
    if [ "${minikube_instance_name}" == "" ]; then
        echo "Must provide a minikube instance name to stop and delete"
        return 1
    fi
    local instance=$(echo ${minikube_instance_name} | sed 's/-/_/g')
    if eval [ ! -z "\${_delete_minikube_$instance}" ]; then
        if eval [ "\${_delete_minikube_$instance}" == "true" ]; then
            minikube delete -p ${minikube_instance_name}
            if eval [ "\${_minikube_vm_driver_$instance}" == "none" ]; then
                # cleanup all the docker containers created by minikube
                docker ps -a -q -f name="k8s" -f status=exited | xargs docker rm -f
            fi
        fi
    fi
    eval unset _delete_minikube_$instance
    eval unset _minikube_vm_driver_$instance
}