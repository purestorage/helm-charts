# PSO Operator

## Overview
PSO Operator is now  the preferred install method for PSO on OpenShift 3.11 and higher versions. 
The PSO Operator packages and deploys the Pure Service Orchestrator (PSO) on OpenShift for dynamic provisioning of persistent volumes on FlashArrays and FlashBlades. The minimum supported version is OpenShift 3.11.
This Operator is created as a [Custom Resource Definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) from the [pure-k8s-plugin Helm chart](https://github.com/purestorage/helm-charts#purestorage-helm-charts-and-helm-operator) using the [Operator-SDK](https://github.com/operator-framework/operator-sdk#overview).
This installation process does not require Helm installation.

## Prerequisites
* OpenShift (3.11+) or Kubernetes (1.11+) cluster installed and running
* Access to a user account that has cluster-admin privileges

## Installation

A single install script sets up the PSO-operator. <br/>
```install.sh --image=<image> --namespace=<namespace> --orchestrator=<ochestrator> -f <values.yaml>```

Parameter list:<br/>
1. ``image`` is the PSO Operator image. If unspecified ``image`` resolves to the released version at [quay.io/purestorage/pso-operator](https://quay.io/purestorage/pso-operator).
2. ``namespace`` is the namespace/project in which the PSO-operator and its entities will be installed. If unspecified, the operator creates and installs in  the ``pso-operator`` namespace.
**PSO Operator MUST be installed in a new project with no other pods. Otherwise an uninstall may delete pods that are not related to the PSO operator.**
3. ``orchestrator`` should be either ``k8s`` or ``openshift`` depending on which orchestrator is being used. If unspecified, ``openshift`` is assumed.
4. ``values.yaml`` is the customized helm-chart configuration parameters. This is a **required parameter** and must contain the list of all backend FlashArrays and FlashBlades. All parameters that need a non-default value must be specified in this file. 
Refer to [Configuration for values.yaml.](../pure-k8s-plugin/README.md#configuration)

### Install script steps:
The install script will do the following:
1. Create New Project<br/>
The script creates a new project (if it does not already exist) with the given namespace. If no namespace parameter is specified, the ``pso-operator`` namespace is used.<br/> 
**OpenShift Note**: In OpenShift 3.11, the default node-selector for a project does not allow PSO Operator to mount volumes on master and infra nodes. 
If you want to mount volumes on master and infra nodes OR run pods in the default namespace using volumes mounted by PSO, then modify the install script as follows.<br/>
```
Existing line:     $KUBECTL adm new-project ${NAMESPACE}

Change to allow volume mounts on master and infra nodes:     $KUBECTL adm new-project ${NAMESPACE} --node-selector=""
```

2. Create a Custom Resource Definition (CRD) for the PSO Operator. <br/>
The script waits for the CRD to be published in the cluster. If after 10 seconds the API server has not setup the CRD, the script times out. To wait longer, pass the parameter 
``--timeout=<timeout_in_sec>`` to the install script.

3. Create RBAC rules for the Operator.<br/>
The PSO Operator needs the following Cluster-level Roles and RoleBindings.


| Resource        | Permissions           | Notes  |
| ------------- |:-------------:| -----:|
| Namespace | Get | PSO Operator needs the ability to get created namespaces |
| Storageclass | Create/Delete | Create and cleanup storage classes to be used for Provisioning |
| ClusterRoleBinding | Create/Delete/Get | PSO Operator needs to create and cleanup a ClusterRoleBinding called ``pure-provisioner-rights`` to the ClusterRole ``system:persistent-volume-provisioner`` for provisioning PVs |
<br/>
In addition, the operator needs access to multiple resources in the project/namespace that it is deployed in to function correctly. Hence it is recommended to install the PSO-operator in the non-default namespace.
<br/>
<br/>
   
4. Creates a deployment for the Operator.<br/>
Finally the script creates and deploys the operator using the customized parameters passed in the ``values.yaml`` file.

## Upgrading

### How to upgrade from helm install to PSO Operator
This upgrade will not impact the in-use volumes/filesystems from data path perspective. However, it will affect the in-flight volume/filesystem management operations. So, it is recommended to stop all the volume/filesystem management operations before doing this upgrade. Otherwise, these operations may need to be retried after the upgrade.
Remove the helm-chart using instructions in https://helm.sh/docs/using_helm/#uninstall-a-release
Once the helm chart has been uninstalled, follow the install instructions [above.](#installation)

### Apply changes in ``values.yaml``
The ``update.sh`` script is used to apply changes from ``values.yaml`` as follows.
```
./update.sh -f values.yaml
```

## Uninstall
To uninstall the PSO Operator, run 
```
oc delete all --all -n <pso-operator-installed-namespace>
```
where ``pso-operator-installed-namespace`` is the project/namespace in which the PSO operator is installed. It is **strongly recommended** to install the PSO Operator in a new project and not add any other pods to this project/namespace. Any pods in this project will be cleaned up on an uninstall. 
