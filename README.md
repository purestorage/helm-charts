# Pure Service Orchestrator (PSO) Helm Charts

## What is PSO?
Pure Service Orchestrator (PSO) delivers storage-as-a-service for containers, giving developers the agility of public cloud with the reliability and security of on-premises infrastructure.

**Smart Provisioning**<br/>
PSO automatically makes the best provisioning decision for each storage request – in real-time – by assessing multiple factors such as performance load, the capacity and health of your arrays, and policy tags.

**Elastic Scaling**<br/>
Uniting all your Pure FlashArray™ and FlashBlade™ arrays on a single shared infrastructure, and supporting file and block as needed, PSO makes adding new arrays effortless, so you can scale as your environment grows.

**Transparent Recovery**<br/>
To ensure your services stay robust, PSO self-heals – so you’re protected against data corruption caused by issues such as node failure, array performance limits, and low disk space.

## Hardware Pre-Requisites
PSO can be used with any of the following hardware appliances and associated minimum version of appliance code:
  * Pure Storage FlashArray (minimum Purity code version 4.8)
  * Pure Storage FlashBlade (minimum Purity version 2.2.0)

## Installation
PSO can be deployed via an Operator or from the Helm chart.

### PSO Operators
PSO has Operator-based install available for both its Flexvolume plugin and CSI plugin. This install method does not need Helm installation. 
The Pure Flex Operator is supported for OpenShift and Kubernetes.
Pure Flex Operator is now the preferred installation method for FlexVolume on OpenShift version 3.11 and higher.<br/>
For installation, see the [Flex Operator Documentation](./operator-k8s-plugin/README.md#overview) or the [CSI Operator Documentation](./operator-csi-plugin/README.md#overview)..

### Helm Chart
**pure-k8s-plugin** deploys PSO Flexvolume plugin on your Kubernetes cluster. 
**pure-csi** deploys PSO CSI plugin on your Kubernetes cluster. 

#### Adding the `pure` repo

```bash
helm repo add pure https://purestorage.github.io/helm-charts
helm repo update
```

#### Helm Setup
Install Helm by following the official documents:
1. For Kubernetes<br/>
https://docs.helm.sh/using_helm#install-helm

2. For OpenShift<br/>
https://blog.openshift.com/getting-started-helm-openshift/<br/>
**Starting OpenShift 3.11 the preferred installation method is using the PSO Operator. Follow the instructions in the [operator directory](./operator/README.md).**

In order to enable Tiller (the server-side component of Helm) to install any type of service across the entire cluster, it's required to grant Tiller a cluster-admin role.

After the Helm installation, configure the cluster admin role for the service account of Tiller. You will need to determine the correct service account.
```bash
# For K8s with example service account "{TILLER_NAMESPACE}:default"
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=${TILLER_NAMESPACE}:default

# For Openshift version < 3.11:
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:${TILLER_NAMESPACE}:tiller
```

For more details, please see https://docs.helm.sh/using_helm/

## Contributing
We welcome contributions. The PSO Helm Charts project is under [Apache 2.0 license](https://github.com/purestorage/helm-charts/blob/master/LICENSE). We accept contributions via GitHub pull requests.

## Report a Bug
For filing bugs, suggesting improvements, or requesting new features, please open an [issue](https://github.com/purestorage/helm-charts/issues).
