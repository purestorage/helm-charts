
# Using Read-Write-Many (RWX) volumes with Kubernetes

## Introduction

The Pure Service Orchestrator Kubernetes CSI driver includes support for Read-Write-Many (RWX) block volumes on FlashArray
starting with version 5.1.0. This feature allows Kubernetes end-users to create persistent block volumes that may be mounted into
multiple pods simultaneously. Persistent volume claims created this way can be mounted exactly the same as a normal pod, only
requiring that `accessModes` contains `ReadWriteMany`.

## Restrictions
Read-Write-Many cannot be used with all combinations of storage classes. Specifically, we prohibit mounting a block volume
as a filesystem as RWX.

| Backend Type | Mount Type | Access Mode | Valid? |
|--------------|------------|-------------|--------|
| Block        | Block      | RWO         | Yes    |
| Block        | Block      | RWX         | Yes    |
| Block        | File       | RWO         | Yes    |
| Block        | File       | RWX         | **No** |
| File         | File       | RWO         | Yes    |
| File         | File       | RWX         | Yes    |

## Examples
To use these examples, install the Pure CSI plugin and apply the following example files.

### For FlashArray/Cloud Block Store

FlashArrays can only be used for RWX volumes with [raw block mounts](https://kubernetes.io/blog/2019/03/07/raw-block-volume-support-to-beta/), as shown in the following example files.

[Raw Block PVC](examples/rwx/pvc-block-many.yaml)

[Example Pods](examples/rwx/pod-block-many.yaml)

To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/rwx/pvc-block-many.yaml
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/rwx/pod-block-many.yaml
# The raw block device will be mounted at /dev/pure-block-device
```

**A note on caching:** while testing using the above examples, it can be remarkably annoying to test writing data between
pods, as it can be difficult to ensure the caches are flushed. One easy way to test the shared block storage is 
`dd if=/dev/urandom of=/dev/pure-block-device bs=512 count=1 oflag=direct` (where `oflag=direct` will bypass caches), and
then read using `dd if=/dev/pure-block-device of=/dev/stdout bs=512 count=1 iflag=direct` (where `iflag=direct` will bypass
caches again).

### For FlashBlade

FlashBlade shares can be easily used for RWX volumes since they use NFS, as shown in the following example files.

[File PVC](examples/rwx/pvc-file-many.yaml)

[Example Pods](examples/rwx/pod-file-many.yaml)

To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/rwx/pvc-file-many.yaml
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/rwx/pod-file-many.yaml
# The NFS volume will be mounted at /data
```
