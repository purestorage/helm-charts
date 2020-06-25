# Special Installation Notes for PSO 5.2 under OpenShift 4.4 Only

## Requirements

- OpenShift 4.4 installed as per Red Hat recommendations
- Only iSCSI connectivity to FlashArray backends has been validated at this time
- Pure Service Orchestrator 5.2 CSI plugin (Operator install method)

## Important Notes

* This documentation note is **ONLY** for OpenShift 4.4 with PSO 5.2 (CSI driver)
* This only refers to the Operator installation method for PSO
* Helm install method has not been modified with these fixes and therefore does not support OSE 4.4 at this time
* Do not use this for previous versions of OpenShift or PSO
* It is expected that these fixes will be merged into later versions of PSO

## Installation

Clone this GitHub repository

```bash
git clone --branch 5.2.0 https://github.com/purestorage/helm-charts.git
cd operator-csi-plugin
```

Create your own `values.yaml`. The easiest way is to copy the default `values.yaml` with `wget` as shown below:

```bash
wget https://raw.githubusercontent.com/purestorage/helm-charts/5.2.0/operator-csi-plugin/values.yaml
```

Run the OSE 4.4 specific install script to set up the Pure CSI Operator.

```bash
install_ose44.sh --namespace=<namespace> --orchestrator=openshift -f <values.yaml>
```

Parameter list:

1. `namespace` is the namespace/project in which the Pure CSI Operator and its entities will be installed. If unspecified, the operator creates and installs in the `pure-csi-operator` namespace.

**Pure CSI Operator MUST be installed in a new project with no other pods, otherwise an uninstall may delete pods that are not related to the Pure CSI Operator.**

2. `values.yaml` is the customized helm-chart configuration parameters. This is a **required parameter** and must contain the list of all backend FlashArray and FlashBlade storage appliances. All parameters that need a non-default value must be specified in this file. 
Refer to [Configuration for values.yaml.](../pure-csi/README.md#configuration)

Please refer back to the main CSI Operator [documentation page](../operator-csi-plugin/README.md#install-script-steps) for more information if necessary.
