
# Using CSI Snapshots and Clones with Kubernetes

## Introduction

The Pure Service Orchestrator Kubernetes CSI driver includes support for snapshots and clones. These features allow Kubernetes end users to capture point-in-time copies of their persistent volume claims, and mount those copies in other Kubernetes Pods, or recover from a snapshot. This enables several use cases, some of which include :

1. Test / Develop against copies of production data quickly (no need to copy large amounts of data)
2. Backup / Restore production volumes.

These features use native Kubernetes APIs to call the feature-set in the underlying storage backend. Currently, only the FlashArray backend can fully support snapshots and clones.

## Dependencies

The following dependencies must be true before the snapshot and clone functionality can be used:

* Kubernetes already running, deployed, configured, etc
* PSO correctly installed and using [Pure CSI Driver v5.0.4](https://github.com/purestorage/helm-charts/releases/tag/5.0.4)+.
* For the snapshot feature, ensure you have Kubernetes 1.13+ installed and the `VolumeSnapshotDataSource` feature gate is enabled
* For the clone feature, ensure you have Kubernetes 1.15+ installed and the `VolumePVCDataSource` feature gate is enabled

### Enabling Feature Gates

To ensure that snapshot and clone functionality can be utilised by the CSI driver use the following commands to ensure that the correct feature gates are open in your Kubernetes deployment.

Note that most Kubernetes deployments have proprietary methods for enabling feature gates and you should check with the deployment vendor if this is the case.

In general you have to ensure that the `kubelet` process has the following switches used during the process startup:

```bash
--feature-gates=VolumeSnapshotDataSource=true,VolumePVCDataSource=true
```

Here are the methods to enable feature gates in a few common deployment tools:

#### kubespray

Edit the file `roles/kubespray-defaults/defaults/main.yaml` and add the following lines in the appropriate locations

```yaml
volume_clones: True
volume_snapshots: True

feature_gate_snap_clone:
  - "VolumeSnapshotDataSource={{ volume_snapshots | string }}"
  - "VolumePVCDataSource={{ volume_clones | string }}"
```

Update the `kube_feature_gates` parameter to enable the feature gates

```yaml
kube_feature_gates: |-
  {{ feature_gate_snap_clone }}
```

#### kubeadm

Edit your kubeadm configuration and modify the `kind` config for the cluster apiServer. An example config would be:

```yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
# patch the generated kubeadm config with some extra settings
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    extraArgs:
      "feature-gates": "VolumeSnapshotDataSource=true"
```

#### kops

Edit the kops `cluster.yaml` and add the following for `kind: Cluster`:

```yaml
spec:
  kubelet:
    featureGates:
      VolumeSnapshotDataSource: "true"
      VolumePVCDataSource: "true"
```

#### OpenShift

CSI snapshot and clone support is only available from OpenShift 4.3.

To enable these features in OpenShift edit the Feature Gate Custom Resource, named `cluster`, in the `openshift-config` project. Add `VolumeSnapshotDataSource` and `VolumePVCDataSource`as enabled feature gates.

### Validating Feature Gates

To validate if your feature gates have been correctly set, check the `api-server` pod in the `kube-system` namespace for one of the nodes in the cluster:

```
kubectl describe -n kube-system pod kube-api-sever-<node name> | grep feature-gates
```

This should result is the following if the feature gates are correctly set.

```
 --feature-gates=VolumeSnapshotDataSource=True,VolumePVCDataSource=True
```

### Examples

Once you have correctly installed PSO on a Kubernetes deployment and the appropriate feature gates have been enabled the following examples can be used to show the use of the snapshot and clone functionality.

These examples start with the assumption that a PVC, called `pure-claim` has been created by PSO under a block related storage class, for example the `pure-block` storage class provided by the PSO installation.

#### Creating snapshots

Use the following YAML to create a snapshot of the PVC `pure-claim`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1alpha1
kind: VolumeSnapshot
metadata:
  name: volumesnapshot-1
spec:
  snapshotClassName: pure-snapshotclass
  source:
    name: pure-claim
    kind: PersistentVolumeClaim
```

This will create a snapshot called `volumesnapshot-1` which can check the status of with

```bash
kubectl describe -n <namespace> volumesnapshot
```

#### Restoring a Snapshot

Use the following YAML to restore a snapshot to create a PVC `pvc-restore-from-volumesnapshot-1`:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-restore-from-volumesnapshot-1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: pure-block
  dataSource:
    kind: VolumeSnapshot
    name: volumesnapshot-1
    apiGroup: snapshot.storage.k8s.io
```

#### Create a clone of a PVC

Use the following YAML to create a clone called `clone-of-pure-claim` of the PVC `pure-claim`:
**Note:** both `clone-of-pure-claim` and `pure-claim` must use the same `storageClassName`.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: clone-of-pure-claim
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: pure-block
  resources:
    requests:
      storage: 10Gi
  dataSource:
    kind: PersistentVolumeClaim
    name: pure-claim
```

**Notes:**

1. _Application consistency:_
The snapshot API does not have any application consistency functionality. If an application-consistent snapshot is needed, the application pods need to be frozen/quiesced from an IO perspective before the snapshot is called. The application then needs to be unquiesced after the snapshot(s) has been created.
