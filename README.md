# Pure Service Orchestrator (PSO) Helm Charts

## What is PSO?

Pure Service Orchestrator (PSO) delivers storage-as-a-service for containers, giving developers the agility of public cloud with the reliability and security of on-premises infrastructure.

**Smart Provisioning**<br/>
PSO automatically makes the best provisioning decision for each storage request – in real-time – by assessing multiple factors such as performance load, the capacity and health of your arrays, and policy tags.

**Elastic Scaling**<br/>
Uniting all your Pure FlashArray™ and FlashBlade™ arrays on a single shared infrastructure, and supporting file and block as needed, PSO makes adding new arrays effortless, so you can scale as your environment grows.

**Transparent Recovery**<br/>
To ensure your services stay robust, PSO self-heals – so you’re protected against data corruption caused by issues such as node failure, array performance limits, and low disk space.

## Software Pre-Requisites

- #### Operating Systems Supported*:
  - CentOS 7
  - CoreOS (Ladybug 1298.6.0 and above)
  - RHEL 7
  - Ubuntu 16.04
  - Ubuntu 18.04
- #### Environments Supported*:
  - Refer to the README for the type of PSO installation required
- #### Other software dependencies:
  - Latest linux multipath software package for your operating system (Required)
  - Latest Filesystem utilities/drivers (XFS by default, Required)
  - Latest iSCSI initiator software for your operating system (Optional, required for iSCSI connectivity)
  - Latest NFS software package for your operating system (Optional, required for NFS connectivity)
  - Latest FC initiator software for your operating system (Optional, required for FC connectivity, *FC Supported on Bare-metal K8s installations only*)
- #### FlashArray and FlashBlade:
  - The FlashArray and/or FlashBlade should be connected to the compute nodes using [Pure's best practices](https://support.purestorage.com/Solutions/Linux/Reference/Linux_Recommended_Settings)
- #### FlashArray User Privilages
  - It is recommend to use a specific FlashArray user, and associated API token, for PSO access control to enable easier array auditing.
  - The PSO user can be local or based on a Directory Service controlled account (assuming DS is configured on the array).
  - The PSO user requires a mininum role level of `storage_admin`.
- #### FlashBlade User Privileges
  - If the FlashBlade is configured to use Directory Services for array management, then a DS controlled account and its associated API token can be used for PSO.
  - The PSO user requires a mininum array management role level of `storage_admin`.
  - Currently ther is no option to create additonal local users on a FlashBlade.

_* Please see release notes for details_

## Hardware Pre-Requisites

PSO can be used with any of the following hardware appliances and associated minimum version of appliance code:
  * Pure Storage FlashArray (minimum Purity code version 4.8)
  * Pure Storage FlashBlade (minimum Purity version 2.2.0)

## Installation

PSO can be deployed via an Operator or from the Helm chart.

### PSO Operator

PSO has Operator-based install available for both its FlexVolume plugin and CSI plugin. This install method does not need Helm installation. 

The Pure Flex Operator is supported for OpenShift and Kubernetes (note that the Flex driver is deprecated in favour of the CSI driver)

Pure Flex Operator is the preferred installation method for FlexVolume on OpenShift version 3.11. The CSI Operator should be used for OpenShift 4.1 and 4.2. 

**Note** Use the CSI Helm install method for OpenShift 4.3 and higher with the adoption of Helm3 in OpenShift.

For installation, see the [Flex Operator Documentation](./operator-k8s-plugin/README.md#overview) or the [CSI Operator Documentation](./operator-csi-plugin/README.md#overview)..

### Helm Chart

**pure-k8s-plugin** deploys PSO FlexVolume plugin on your Kubernetes cluster - the Flex Driver is now deprecated 

**pure-csi** deploys PSO CSI plugin on your Kubernetes cluster. 

#### Helm Setup

Install Helm by following the official documents:
1. For Kubernetes<br/>
https://docs.helm.sh/using_helm#install-helm

2. For OpenShift<br/>
**In OpenShift 3.11 the Red Hat preferred installation method is using an Operator. Follow the instructions in the [PSO operator directory](./operator/README.md).**


Refer to the [k8s-plugin README](./pure-k8s-plugin/README.md) or the [csi-plugin README](./pure-csi/README.md) for further installation steps.

## PSO on the Internet

[Checkout a list of some blogs related to Pure Service Orchestrator](./docs/blog_posts.md)

## Contributing
We welcome contributions. The PSO Helm Charts project is under [Apache 2.0 license](https://github.com/purestorage/helm-charts/blob/master/LICENSE). We accept contributions via GitHub pull requests.

## Report a Bug
For filing bugs, suggesting improvements, or requesting new features, please open an [issue](https://github.com/purestorage/helm-charts/issues).
