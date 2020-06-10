# Upgrading from PSO FlexDriver to PSO CSI

## Introduction

With the deprecation of FlexDriver by the Kubernetes community, all external persistent storage volumes should now be managed by a CSI driver.

Unfortunately, there is no seamless way to migrate a volume managed by a FlexDriver to being managed by a CSI driver and the PSO FlexDriver cannot be run in parallel with the PSO CSI driver.

This document provides one strategy to migrate volumes created and managed by the PSO FlexDriver to management by the PSO CSI driver.

Note that this requires all access to the persistent volume to be stopped whilst this migration takes place.

## Upgrade to PSO CSI Driver

The first phase of the migration process is to upgrade the PSO driver from the Flex version to the CSI version. 

During this upgrade all existing persistent volumes and volume claims are unaffected and the applications using these will be unaffected.

First, uninstall the PSO FlexDriver by running the `helm delete` command. If you have installed the FlexDriver using the Operator then follow the process [here](../operator-k8s-plugin#uninstall) to uninstall.

Secondly, install the PSO driver using the instructions provided [here](../pure-csi#how-to-install). Note that this procedures requires Helm3.

At this point the PSO driver has been upgraded to use CSI and all new persistent volumes created will be managed by the CSI process.

All volumes managed by the uninstalled FlexDriver process will still be in existance but cannot be managed, at this point, by the CSI process.

## Migrating Flex PVs to CSI control

**This process requires that the PSO CSI version installed is a minimum of 5.2.0**

### Identify all existng, FlexDriver controlled, persistent volumes.

You can determine if a PV is Flexdriver controlled by using the command:

```bash
kubectl get pv -o json | jq -j '.items[] | "PV: \(.metadata.name), Driver: \(.spec.flexVolume.driver), PVC: \(.spec.claimRef.name), Namespace: \(.spec.claimRef.namespace)\n"'
```
Persistent volumes where the driver equals `pure/flex` need to be migrated to CSI control.

Once a PV has been identified as requiring migration you must stop the application pod using the PVC associated with the PV.

To determine which pods are using which PVCs use the following command:

```bash
kubectl get pod -o json --all-namespaces | jq -j '.items[] | "PVC: \(.spec.volumes[].persistentVolumeClaim.claimName), Pod: \(.metadata.name), Namespace: \(.metadata.namespace)\n"' | grep -v null
```

When the application pod has been stopped, perform the following command on the PV to be migrated:

```bash
kubectl patch pv <your-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

### Delete the PVC and PV (don't panic!!)

* Delete the associated PVC and notice that the associated PV is not deleted.
* Manually delete the PV

These actions will leave the underlying volume on the backend storage ready for import.

### Importing the backend volume into CSI control

Now that the PVC and PV have been deleted from Kuberentes, it is necessary to import the underlying volume on the backend back into Kubernetes control, but using the CSI driver.

To achieve this use the volume import facility in PSO as documented [here](./csi-volume-import.md).

Ensure that the `persistentVolumeReclaimPolicy` is set to `Delete`. This will ensure that when the time comes for the PV to be deleted, the CSI driver will correctly delete the backend volume.

Remember to create the PVC with the same name that the application used before so that when the application pod restarts it will attach to the correct PV.
