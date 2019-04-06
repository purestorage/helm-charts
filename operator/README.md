# PureStorage Helm Operator

## Prerequisites
* Openshift(3.11+) or Kubernetes(1.11+) cluster installed and running
* Access to a user account that has cluster-admin privileges

## Installation

A single install script will setup the PSO-operator. <br/>
```install.sh --image=<image> --namespace=<namespace> --orchestrator=<ochestrator> -f <values.yaml>```

Parameter list:<br/>
1. ``image`` is the PSO-Operator image. If unspecified it will resolve to the released version at quay.io/purestorage/pso-operator
2. ``namespace`` is the namespace/project in which the PSO-operator and its entities will be installed. If unspecified the operator will create and install in 'psooperator' namespace.
**It is recommended to install PSO Operator in a new project with no other pods.**
3. ``orchestrator`` should be ``k8s`` or ``openshift`` depending on which orchestrator is being used. If unspecified ``openshift`` is assumed.
4. ``values.yaml`` is the customized helm-chart configuration parameters. This is a **required parameter** and must contain the list of all backend FlashArrays and FlashBlades. All parameters that need a non-default value must be specified in this file.

### Install script steps:
The install script will do the following:
1. Create New Project<br/>
The script will create a new project (if it does not already exist) with the given namespace. If no namespace parameter is specified 'psooperator' namespace is used.<br/> 
**Openshift Note**: In Openshift 3.11 the default node-selector for a project does not allow PSO-operator to mount volumes on master and infra nodes. 
If you want to mount volumes on master and infra nodes OR run pods in the default namespace using PSO-volumes then modify the install script as follows.<br\>
```
Existing line:     $KUBECTL adm new-project ${NAMESPACE}

Change to allow volume mounts on master and infra nodes:     $KUBECTL adm new-project ${NAMESPACE} --node-selector=""
```

2. Create a Custom Resource Definition (CRD) for the PSO-Operator. <br/>
The script will wait for the CRD to be published in the cluster. The script waits uptil 10sec for the API server to setup the CRD and times out. To wait longer pass the parameter ```--timeout=<timeout_in_sec>``` to the install script.

3. Create RBAC rules for the Operator.<br/>
The PSO-Operator needs the following Cluster-level Roles and RoleBindings.


| Resource        | Permissions           | Notes  |
| ------------- |:-------------:| -----:|
| Namespace | Get | PSO-Operator needs the ability to get created namespaces |
| Storageclass | Create/Delete | Create and cleanup storage classes to be used for Provisioning |
| ClusterRoleBinding | Create/Delete | PSO-Operator needs to create and cleanup a ClusterRoleBinding called 'pure-provisioner-rights' to ClusterRole system:persistent-volume-provisioner for provisioning PVs |
| ClusterRoleBinding | Get permission on ResourceName 'pure-provisioner-rights' | PSO-operator needs the ability to get the ClusterRoleBinding it has created for provisioning. |
<br/>
In addition the operator needs access to multiple resources in the project/namespace that it is deployed to function correctly. Hence it is recommended to install the PSO-operator in the non-default namespace.
<br/>
   
4. Creates a deployment for the Operator.<br/>
Finally the script will create an deploy the operator using the customized parameters passed in the values.yaml file.


## Uninstall
To unsintall the PSO Operator delete the project/namespace in which the PSO operator is installed. It is recommended to install the PSO Operator in a new project and not add any other pods to this project/namespace. 
