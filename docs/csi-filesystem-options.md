
# Using Per-Volume FileSystem Options with Kubernetes

## Introduction

The Pure Service Orchestrator Kubernetes CSI driver includes support for per-volume basis filesystem (FS) options starting with version 5.0.5.
The feature allows Kubernetes end-users to create persistent volumes with customizable filesystem options on a per-volume basis.
Users can customize the filesystem type (`FsType`) with create options (`CreateOptions`) during the volume staging phase and customize mount options (`MountOptions`) during the volume publish phase.    

The feature leverages Kubernetes `StorageClass` to carry the customized FS options to the underlying storage backend. 
Before this feature, users could only set up these parameters via [configuration](../pure-csi/README.md) in the values.yaml file. Then all persistent volumes used the same options, and the settings could not be changed after PSO had loaded.
With this feature, users can customize the FS options for persistent volumes on-the-fly through various StorageClass settings to meet different application needs.


## Dependencies

The following dependencies must be true before the customized filesystem options can be used:

* Kubernetes already running, deployed, configured, etc
* For the `MountOptions` feature, ensure you have Kubernetes 1.8+ installed.
* PSO correctly installed and using [Pure CSI Driver v5.0.5](https://github.com/purestorage/helm-charts/releases/tag/5.0.5)+.

##  FileSystem Options
PSO leverages Kubernetes `StorageClass` to pass the customized FS options to the underlying storage backend. If the FS options are specified in the `StorageClass`, it will override the default values from the values.yaml.
The default values will only apply when no FS options in the `StorageClass`.
### FsType
The CSI external-provisioner allows users to set `FsType` via key-value parameters map in the `StorageClass`. You can use the pre-defined key `"csi.storage.k8s.io/fstype"` to set up the `FsType` like this:

```yaml
parameters:
    csi.storage.k8s.io/fstype: vfat
```

### CreateOptions
PSO allows users to set `CreateOptions` via key-valume parameters map in the `StorageClass`.  You can use the pre-defined key `"createoptions"` to set up the `CreateOptions` like this:

```yaml
parameters:
    createoptions: -F 32 -f 2 -S 512 -s 1 -R 32
```

### MountOptions
Persistent Volumes that are dynamically created by a `StorageClass` will have the `MountOptions` specified in the _mountOptions_ field of the `StorageClass`. You can set the options like this: 
```
mountOptions:
    - nosuid
    - discard
```

**Notes:**

1. _**Native mkfs and mount support**:_
Please make sure your worker nodes support the `FsType` with the correct `CreateOptions` you specify in the `StorageClass`.

   During the Volume staging phase, PSO transfer these parameters to our driver and creates the file system for a volume using the command like this `mkfs.<FsType> -o <CreateOptions> /dev/dm-0`. Failure of mkfs operation will lead pod volume attachment failures and pod will be stuck in pending state. It is also true when you mount with incorrect `MountOptions`.
For **FlashBlade**, make sure your worker nodes have NFS utilities package installed:
``` bash
 yum install -y nfs-utils
```

2. _**FlashBlade support:**_ When you backend storage type is FB, PSO will ignore the `FsType` and `CreateOptions` parameters by default since FB does not allow users to format the filesystem when you attach volumes. The default filesystem for FB is `nfs`. However, users can still specify the `MountOptions` to mount volumes.   

3. _**Kubenetes default Filesystem:**_ 
Kubernetes uses `ext4` as the default file systems. If users do not specify `FsType` in the `StorageClass`, K8s will pass the default `ext4` to the driver.
PSO recommends users to use `xfs` to achieve the best performance.

4. _**Default "discard" mount option:**_ By default, PSO automatically adds a "discard" option while mounting the volume to achieve the best performance unless users specifically add the "nodiscard" option, which PSO does not recommend.

## Example of StorageClass for FlashArray

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: pure-block-xfs
  labels:
    kubernetes.io/cluster-service: "true"
provisioner: pure-csi 
parameters:
    backend: block
    csi.storage.k8s.io/fstype: xfs
    createoptions: -q
mountOptions:
      - discard
```
To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/fsoptions/pure-block-xfs.yaml
```
## Example of StorageClass for FlashBlade

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: pure-file-nfs
  labels:
    kubernetes.io/cluster-service: "true"
provisioner: pure-csi 
parameters:
    backend: file
mountOptions:
      - nfsvers=3
      - tcp
```
To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/fsoptions/pure-file-nfs.yaml
```