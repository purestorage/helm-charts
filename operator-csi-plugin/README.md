# Pure CSI Operator

## Overview
The Pure CSI Operator packages and deploys the Pure Service Orchestrator (PSO) CSI plugin on Kubernetes for dynamic provisioning of persistent volumes on FlashArray and FlashBlade storage appliances. 
This Operator is created as a [Custom Resource Definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) from the [pure-csi Helm chart](https://github.com/purestorage/helm-charts#purestorage-helm-charts-and-helm-operator) using the [Operator-SDK](https://github.com/operator-framework/operator-sdk#overview).
This installation process does not require Helm installation.

## Platform and Software Dependencies
- #### Operating Systems Supported*:
  - CentOS 7
  - CoreOS (Ladybug 1298.6.0 and above)
  - RHEL 7
  - Ubuntu 16.04
- #### Environments Supported*:
  - Kubernetes 1.13+
    - Access to a user account that has cluster-admin privileges.
  - CSI specification v1.0.0
- #### Other software dependencies:
  - Latest linux multipath software package for your operating system (Required)
  - Latest Filesystem utilities/drivers (XFS by default, Required)
  - Latest iSCSI initiator software for your operating system (Optional, required for iSCSI connectivity)
  - Latest NFS software package for your operating system (Optional, required for NFS connectivity)
  - Latest FC initiator software for your operating system (Optional, required for FC connectivity)
- #### FlashArray and FlashBlade:
  - The FlashArray and/or FlashBlade should be connected to the compute nodes using [Pure's best practices](https://support.purestorage.com/Solutions/Linux/Reference/Linux_Recommended_Settings)

_* Please see release notes for details_

## Additional configuration for Kubernetes 1.13 Only
For details see the [CSI documentation](https://kubernetes-csi.github.io/docs/csi-driver-object.html). 
In Kubernetes 1.12 and 1.13 CSI was alpha and is disabled by default. To enable the use of a CSI driver on these versions, do the following:

1. Ensure the feature gate is enabled via the following Kubernetes feature flag: ```--feature-gates=CSIDriverRegistry=true```
2. Either ensure the CSIDriver CRD is installed cluster with the following command:
```
$> kubectl create -f https://raw.githubusercontent.com/kubernetes/csi-api/master/pkg/crd/manifests/csidriver.yaml
```

## Installation

Clone this GitHub repository, selecting the version of the operator you wish to install. We recommend using the latest released version. Information on this can be found [here](https://github.com/purestorage/helm-charts/releases)</br>
```
git clone --branch <version> https://github.com/purestorage/helm-charts.git
cd operator-csi-plugin
```

Create your own `values.yaml`. The easiest way is to copy the default [./values.yaml](./values.yaml) with `wget`.

Run the install script to set up the Pure CSI Operator. <br/>
```install.sh --image=<image> --namespace=<namespace> --orchestrator=<ochestrator> -f <values.yaml>```

Parameter list:<br/>
1. ``image`` is the Pure CSI Operator image. If unspecified ``image`` resolves to the released version at [quay.io/purestorage/pso-operator](https://quay.io/purestorage/pso-operator).
2. ``namespace`` is the namespace/project in which the Pure CSI Operator and its entities will be installed. If unspecified, the operator creates and installs in  the ``pure-csi-operator`` namespace.
**Pure CSI Operator MUST be installed in a new project with no other pods. Otherwise an uninstall may delete pods that are not related to the Pure CSI Operator.**
3. ``orchestrator`` defaults to ``k8s``. Options are ``k8s`` or ``openshift``. 
4. ``values.yaml`` is the customized helm-chart configuration parameters. This is a **required parameter** and must contain the list of all backend FlashArray and FlashBlade storage appliances. All parameters that need a non-default value must be specified in this file. 
Refer to [Configuration for values.yaml.](../pure-csi/README.md#configuration)

### Install script steps:
The install script will do the following:
1. Create New Project.<br/>
The script creates a new project (if it does not already exist) with the given namespace. If no namespace parameter is specified, the ``pure-csi-operator`` namespace is used.<br/> 

2. Create a Custom Resource Definition (CRD) for the Pure CSI Operator. <br/>
The script waits for the CRD to be published in the cluster. If after 10 seconds the API server has not setup the CRD, the script times out. To wait longer, pass the parameter 
``--timeout=<timeout_in_sec>`` to the install script.

3. Create RBAC rules for the Operator.<br/>
The Pure CSI Operator needs the following Cluster-level Roles and RoleBindings.


| Resource        | Permissions           | Notes  |
| ------------- |:-------------:| -----:|
| Namespace | Get | Pure CSI Operator needs the ability to get created namespaces |
| Storageclass | Create/Delete | Create and cleanup storage classes to be used for Provisioning |
| ClusterRoleBinding | Create/Delete/Get | PSO Operator needs to create and cleanup a ClusterRoleBinding used by the external-provisioner sidecar and cluster-driver-registrar sidecar(only K8s 1.13) |
<br/>
The operator also needs all the Cluster-level Roles that are needed by the external-provisioner and cluster-driver-registrar sidecars.
In addition, the operator needs access to multiple resources in the project/namespace that it is deployed in to function correctly. Hence it is recommended to install the Pure CSI Operator in the non-default namespace.
<br/>
<br/>
   
4. Creates a deployment for the Operator.<br/>
Finally the script creates and deploys the operator using the customized parameters passed in the ``values.yaml`` file.

## Upgrading

### How to upgrade from helm install to Pure CSI Operator
This upgrade will not impact the in-use volumes/filesystems from data path perspective. However, it will affect the in-flight volume/filesystem management operations. So, it is recommended to stop all the volume/filesystem management operations before doing this upgrade. Otherwise, these operations may need to be retried after the upgrade.

Remove the helm-chart using instructions in https://helm.sh/docs/using_helm/#uninstall-a-release.
Once the helm chart has been uninstalled, follow the install instructions [above.](#installation)

### Apply changes in ``values.yaml``
The ``update.sh`` script is used to apply changes from ``values.yaml`` as follows.
```
./update.sh -f values.yaml
```

## Uninstall
To uninstall the Pure CSI Operator, run 
```
kubectl delete all --all -n <pure-csi-operator-installed-namespace>
```
where ``pure-csi-operator-installed-namespace`` is the project/namespace in which the Pure CSI Operator is installed. It is **strongly recommended** to install the Pure CSI Operator in a new project and not add any other pods to this project/namespace. Any pods in this project will be cleaned up on an uninstall. 

If you are using OpenShift, replace `kubectl` with `oc`.
To completely remove the CustomResourceDefinition used by the Operator run
```
kubectl delete crd psoplugins.purestorage.com
```
If the CRD fails to delete you may be experiencing a known issue. Resolve this by running:
```
kubectl patch crd/psoplugins.purestorage.com -p '{"metadata":{"finalizers":[]}}' --type=merge
```
If you are using OpenShift, replace `kubectl` with `oc` in the above commands.

# License
https://www.purestorage.com/content/dam/purestorage/pdf/legal/pure-plugin-end-user-license-agmt-sept-18-2017.pdf
