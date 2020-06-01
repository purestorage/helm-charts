
# Expanding CSI persistent volumes with Kubernetes

## Introduction

The Pure Service Orchestrator Kubernetes CSI driver includes support for CSI volume expansion starting with version 5.2.0.

The feature allows Kubernetes end-users to expand a persistent volume (PV) after creation by resizing a dynamically provisioned persistent volume claim (PVC).
The end-users are able to edit the `allowVolumeExpansion` boolean flag in Kubernetes `StorageClass` to modify the permission whether a PVC resizing is allowed. 

## Prerequisites

The following prerequisites must be true to ensure the function can work properly:

* Only dynamically provisioned PVCs can be resized.
* Only allow volume size expansion, shrinking a volume is not allowed.
* The `StorageClass` that provisions the PVC must support resize. `allowVolumeExpansion` flag is set to true by default in all PSO `StorageClass` since version 5.2.0.
* The PVC `accessMode` must be `ReadWriteOnce` or `ReadWriteMany`.

### Note

Any PVC creted using a StorageClass where the `Parameters:   backend=block` is true will only be resized upon a (re)start of the pod bound to the PVC. 

## Dependencies

* Kubernetes already running, deployed, configured, etc.
* Kubernetes supports CSI Volume Expansion as beta since 1.16 and is expected to GA in Kubernetes 1.19, so ensure you have Kubernetes 1.16+ installed. [More Info](https://kubernetes-csi.github.io/docs/volume-expansion.html)
* PSO correctly installed and using [Pure CSI Driver v5.2.0](https://github.com/purestorage/helm-charts/releases/tag/5.2.0)+.


## Example usages

PSO CSI driver supports `ONLINE` volume expansion capability, i.e. expanding an in-use PersistentVolumeClaim.
For more details check the [CSI spec](https://github.com/container-storage-interface/spec/blob/master/spec.md) please. 
 
### FlashArray StorageClass "pure-block" volume expansion

#### 1. Ensure `allowVolumeExpansion` is set to `true` in `pure-block` StorageClass:

To ensure that the StorageClass has the correct setting run the following command

```bash
kubectl patch sc pure-block --type='json' -p='[{"op": "add", "path": "/allowVolumeExpansion", "value": true }]'
```

#### 2. Create a PVC:

Example PVC:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  # Referenced in pod.yaml for the volume spec
  name: pure-claim-block
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: pure-block
```

To create:

```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/volexpansion/pvc-block.yaml
```

#### 3. Start a Pod to use the PVC:

Example Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  volumes:
  - name: pure-vol
    persistentVolumeClaim:
        claimName: pure-claim-block
  containers:
  - name: nginx
    image: nginx
    # Configure a mount for the volume We define above
    volumeMounts:
    - name: pure-vol
      mountPath: /data
    ports:
    - containerPort: 80
```

To create:

```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/volexpansion/pod-block.yaml
```

#### 4. Expand the PVC:

Patch the PVC to a larger size, e.g. 20Gi:

```bash
kubectl patch pvc pure-claim-block -p='{"spec": {"resources": {"requests": {"storage": "20Gi"}}}}'
```

Check that the PV is already resized successfully, but notice the PVC size is not changed, because a Pod (re-)start is required:

```bash
# kubectl get pvc pure-claim-block
NAME               STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pure-claim-block   Bound     pvc-b621957b-2828-4b75-a737-251916c05cb6   10Gi       RWO            pure-block     56s
# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                      STORAGECLASS   REASON    AGE
pvc-b621957b-2828-4b75-a737-251916c05cb6   20Gi       RWO            Delete           Bound     default/pure-claim-block   pure-block               68s

```
Check the PVC conditions:

```bash
# kubectl get pvc pure-claim -o yaml
...
status:
  conditions:
    message: Waiting for user to (re-)start a pod to finish file system resize of volume on node.
    status: "True"
    type: FileSystemResizePending
  phase: Bound
```

#### 5. Restart the Pod:

To restart:

```bash
kubectl delete -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/volexpansion/pod-block.yaml
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/volexpansion/pod-block.yaml
```
Verify the PVC is resized successfully after Pod is running:
```bash

# kubectl get pvc pure-claim-block
NAME               STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pure-claim-block   Bound     pvc-b621957b-2828-4b75-a737-251916c05cb6   20Gi       RWO            pure-block     2m46s
```

### FlashBlade StorageClass "pure-file" volume expansion

The procedure should be exactly the same as FlashArray StorageClass `pure-block` volume expansion, except no Pod (re-)start is required.
The PV and PVC should show the updated size immediately.

#### 1. Ensure `allowVolumeExpansion` is set to `true` in `pure-file` StorageClass:

To ensure that the StorageClass has the correct setting run the following command

```bash
kubectl patch sc pure-file --type='json' -p='[{"op": "add", "path": "/allowVolumeExpansion", "value": true }]'
```

#### 2. Create a PVC:

```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/volexpansion/pvc-file.yaml
```

#### 3. Start a Pod to use the PVC:

```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/volexpansion/pod-file.yaml
```

#### 4. Expand the PVC:

```bash
kubectl patch pvc pure-claim-file -p='{"spec": {"resources": {"requests": {"storage": "20Gi"}}}}'
```

Check that both the PV and PVC are immeadiately expanded. No pod restart is required.

```bash
# kubectl get pvc pure-claim-file
NAME               STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pure-claim-file    Bound     pvc-2ba56b33-3412-2965-f4e4-983de21ba772   20Gi       RWO            pure-file      25s
# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                      STORAGECLASS   REASON    AGE
pvc-2ba56b33-3412-2965-f4e4-983de21ba772   20Gi       RWO            Delete           Bound     default/pure-claim-file    pure-file                27s
```

