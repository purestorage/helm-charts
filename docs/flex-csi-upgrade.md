# Upgrading from PSO FlexDriver to PSO CSI

## Introduction

With the deprecation of FlexDriver by the Kubernetes community, all external persistent storage volumes should now be managed by a CSI driver.

Unfortunately, there is no seamless way to migrate a volume managed by a FlexDriver to being managed by a CSI driver and the PSO FlexDriver cannot be run in parallel with the PSO CSI driver.

This document provides one strategy to migrate volumes created and managed by the PSO FlexDriver to management by the PSO CSI driver.

Note that this requires all access to the persistent volume to be stopped whilst this migration takes place.

## Scale Down Applications

The fisrt phase of the upgrade is to scale down all your deployments and statefulsets to zero to ensure that all PVs and PVs are not being accessed by application.

Use the `kubectl scale --replicas=0` command to perform this.

## Upgrade to PSO CSI Driver

The second phase of the migration process is to upgrade the PSO driver from the Flex version to the CSI version. 

During this upgrade all existing persistent volumes and volume claims are unaffected.

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

Once a PV has been identified as requiring migration you can perform the following command on the PV:

```bash
kubectl patch pv <your-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

### Delete the PVC and PV (don't panic!!)

**Before proceeding keep a record of which PVC was bound to which PV - you will need this later in the process**

* Delete the associated PVC and notice that the associated PV is not deleted

* Manually delete the PV

These actions will leave the underlying volume on the backend storage ready for import.

### Importing the backend volume into CSI control

Now that the PVC and PV have been deleted from Kubernetes, it is necessary to import the underlying volume on the backend back into Kubernetes control, but using the CSI driver.

To achieve this use the volume import facility in PSO as documented [here](./csi-volume-import.md).

* In this step the `volumeHandle` referenced will be the PV name prefixed by the Pure namespace, defined for your PSO installation, and a hyphen. The Pure namespace setting is available in the PSO installation `values.yaml`.

  For example:

  A PV called `pvc-70c5a426-c704-4478-b034-2d233ec673bc` and a Pure namespace of `k8s` will require the `volumeHandle` to be `k8s-pvc-70c5a426-c704-4478-b034-2d233ec673bc`.

* The `name` setting in `claimRef` must match the PVC name linked to the PV name you are importing. **Reference the record of these you obtained earlier**.

* Finally, ensure that the `persistentVolumeReclaimPolicy` is set to `Delete`. This will ensure that when the time comes for the PV to be deleted, the CSI driver will correctly delete the backend volume.

## Scale Up Applications

The final phase of the upgrade is to scale up all your deployments and statefulsets to their original replica size.

Use the `kubectl scale --replicas=<replica count>` command to perform this.
