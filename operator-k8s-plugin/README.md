**The Flex Volume Driver has been deprecated in favour of the CSI Driver**

Flex should only be used where the CSI driver is not supported due to a lower level of Kubernetes version.

# Pure Flex Operator

## Overview
Pure Flex Operator is the preferred install method for PSO on OpenShift 3.11. 
The Pure Flex Operator packages and deploys the Pure Service Orchestrator (PSO) Flexvolume driver on OpenShift for dynamic provisioning of persistent volumes on FlashArray and FlashBlade storage appliances.
This Operator is created as a [Custom Resource Definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) from the [pure-k8s-plugin Helm chart](https://github.com/purestorage/helm-charts#purestorage-helm-charts-and-helm-operator) using the [Operator-SDK](https://github.com/operator-framework/operator-sdk#overview).
This installation process does not require Helm installation.


## Platform and Software Dependencies
- #### Operating Systems Supported*:
  - CentOS 7
  - CoreOS (Ladybug 1298.6.0 and above)
  - RHEL 7
  - Ubuntu 16.04
  - Ubuntu 18.04
- #### Environments Supported*:
  - Kubernetes 1.11+
    - Access to a user account that has cluster-admin privileges.
  - OpenShift 3.11
    - Access to a user account that has cluster-admin privileges.
    - [Dynamic provisioning](https://docs.openshift.com/container-platform/3.11/install_config/persistent_storage/dynamically_provisioning_pvs.html#overview) enabled in the master nodes.
    - [Controller attach-detach disabled](https://docs.openshift.com/container-platform/3.11/install_config/persistent_storage/enabling_controller_attach_detach.html#configuring-nodes-to-enable-controller-managed-attachment-and-detachment) in all nodes the flex driver is running on.
- #### Other software dependencies:
  - Latest linux multipath software package for your operating system (Required)
  - Latest Filesystem utilities/drivers (XFS by default, Required)
  - Latest iSCSI initiator software for your operating system (Optional, required for iSCSI connectivity)
  - Latest NFS software package for your operating system (Optional, required for NFS connectivity)
  - Latest FC initiator software for your operating system (Optional, required for FC connectivity, *FC Supported on Bare-metal K8s installations only*)
- #### FlashArray and FlashBlade:
  - The FlashArray and/or FlashBlade should be connected to the compute nodes using [Pure's best practices](https://support.purestorage.com/Solutions/Linux/Reference/Linux_Recommended_Settings)

_* Please see release notes for details_

## Installation

Clone this GitHub repository, selecting the version of the operator you wish to install. We recommend using the latest released version.</br>
```
git clone --branch <version> https://github.com/purestorage/helm-charts.git
cd operator-k8s-plugin
```

Create your own `values.yaml`. The easiest way is to copy the default [./values.yaml](./values.yaml) with `wget`.

Run the install script to set up the PSO-operator.

```bash
install.sh --image=<image> --namespace=<namespace> --orchestrator=<ochestrator> -f <values.yaml>
```

Parameter list:
1. ``image`` is the Pure Flex Operator image. If unspecified ``image`` resolves to the released version at [quay.io/purestorage/pso-operator](https://quay.io/purestorage/pso-operator).
2. ``namespace`` is the namespace/project in which the Pure Flex Operator and its entities will be installed. If unspecified, the operator creates and installs in  the ``pso-operator`` namespace.
**Pure Flex Operator MUST be installed in a new project with no other pods. Otherwise an uninstall may delete pods that are not related to the Pure Flex operator.**
3. ``orchestrator`` should be either ``k8s`` or ``openshift`` depending on which orchestrator is being used. If unspecified, ``k8s`` is assumed.
4. ``values.yaml`` is the customized helm-chart configuration parameters. This is a **required parameter** and must contain the list of all backend FlashArray and FlashBlade storage appliances. All parameters that need a non-default value must be specified in this file. 
Refer to [Configuration for values.yaml.](../pure-k8s-plugin/README.md#configuration)

### Install script steps:
The install script will do the following:
1. Create New Project.<br/>
The script creates a new project (if it does not already exist) with the given namespace. If no namespace parameter is specified, the ``pso-operator`` namespace is used.<br/> 
**OpenShift Note**: In OpenShift 3.11, the default node-selector for a project does not allow PSO Operator to mount volumes on master and infra nodes. 
If you want to mount volumes on master and infra nodes OR run pods in the default namespace using volumes mounted by PSO, then set `--node-selector` flag to `""` when running the install script as follows.<br/>

```bash
install.sh --image=<image> --namespace=<namespace> --orchestrator=<ochestrator> --node-selector=<node-selector> -f <values.yaml>
```

2. Create a Custom Resource Definition (CRD) for the PSO Operator.<br/>
The script waits for the CRD to be published in the cluster. If after 10 seconds the API server has not setup the CRD, the script times out. To wait longer, pass the parameter 
``--timeout=<timeout_in_sec>`` to the install script.

3. Create RBAC rules for the Operator.<br/>
The Pure Flex Operator needs the following Cluster-level Roles and RoleBindings.


| Resource        | Permissions           | Notes  |
| ------------- |:-------------:| -----:|
| Namespace | Get | PSO Operator needs the ability to get created namespaces |
| Storageclass | Create/Delete | Create and cleanup storage classes to be used for Provisioning |
| ClusterRoleBinding | Create/Delete/Get | PSO Operator needs to create and cleanup a ClusterRoleBinding called ``pure-provisioner-rights`` to the ClusterRole ``system:persistent-volume-provisioner`` for provisioning PVs |

In addition, the operator needs access to multiple resources in the project/namespace that it is deployed in to function correctly. Hence it is recommended to install the PSO-operator in the non-default namespace.
   
4. Creates a deployment for the Operator.<br/>
Finally the script creates and deploys the operator using the customized parameters passed in the ``values.yaml`` file.

### Apply changes in ``values.yaml``
The ``update.sh`` script is used to apply changes from ``values.yaml`` as follows.

```bash
./update.sh -f values.yaml
```

## Using Snapshots with a FlashArray

More details on using the snapshot functionality can be found [here](../docs/flex-snapshot-for-flasharray.md)

## Using Labels to control volume topology

More details on using configuration labels can be found [here](../docs/flex-volume-using-labels.md)

## Upgrading FlexDriver Operator version
To upgrade the version of your FlexDriver perform the following actions:
1. Update your `helm-charts` directory using `git fetch` and `git rebase`. If you have modified any files you will need to commit these before performing the `rebase`. For more details see [here](https://git-scm.com/docs/git-rebase) and [here](https://git-scm.com/book/en/v2/Git-Branching-Rebasing).
2. Ensure that your local `values.yaml` file is modified to reflect the `tag` version of the `purestorage/k8s` FlexDriver image you wish to upgrade to, for example: `2.7.0`
3. Run the `upgrade.sh` script as follows:<br/>

```bash
./upgrade.sh -f values.yaml --version=<new_version>
```

where `<new_version>` refers to the PSO Operator image version, such as `0.2.0`, you wish to upgrade to.

**NOTE:** The Operator image version and FlexDriver version must be compatible

## Uninstall FlexDriver Operator
To uninstall the Pure FlexVolume Operator, run

```bash
kubectl delete PSOPlugin/psoplugin-operator -n <pure-k8s-operator-installed-namespace>
kubectl delete all --all -n <pure-k8s-operator-installed-namespace>
```

where ``pure-k8s-operator-installed-namespace`` is the project/namespace in which the Pure FlexDriver Operator is installed. It is **strongly recommended** to install the Pure FlexDriver Operator in a new project and not add any other pods to this project/namespace. Any pods in this project will be cleaned up on an uninstall.

To completely remove the CustomResourceDefinition used by the Operator run

```bash
kubectl delete crd psoplugins.purestorage.com
```

If you are using OpenShift, replace `kubectl` with `oc` in the above commands.

# License
https://www.purestorage.com/content/dam/pdf/en/legal/pure-storage-plugin-end-user-license-agreement.pdf
