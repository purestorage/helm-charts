
# Apply Storage Quality-of-Service (QoS) Control on PSO StorageClass

## Summary
Pure Storage FlashArray Quality-of-Service (QoS) allows users to impose QoS limits on their persistent volumes created and managed by PSO on Kubernetes clusters. QoS limits are applied on a per volume basis - these are **not** cumulative for all volumes created using a specific StorageClass. Whenever throughput exceeds the limit specified, throttling occurs. Specifically, PSO enables users to control their volumes' bandwidth limit and/or IOPS limit. The two parameters are passed in through parameter fields in `StorageClasses` or `PersistentVolumes`. 

This feature is only supported on Pure Storage FlashArray block storage.

#### Usecases:
1. New volume provisioning
2. Cloning from existing volume
3. Importing a volume to k8s

## Dependencies
* Pure CSI driver 6.0.0+. **Estimated release date 7/2020.**
* At least one FlashArray with Purity Version 5.3.0+ (REST API version 1.17+)

## General guidance
For new volume provisioning:
1. If the user does not own any FlashArray that supports QoS (5.3 and above), the volume will NOT be provisioned successfully. 
2. If the user owns multiple devices, PSO will look for the FlashArray that supports QoS and provision the volume on that device. If multiple arrays support QoS, the existing algorithm is leveraged to determine the array to provision the volume. If storage topology is being used for provisioning, these rules will apply first before checks are made for QoS support.
3. To enable bandwidth limit add `bandwidth_limit` as a parameter in the StorageClass
4. To enable IOPS limit add `iops_limit` as a parameter in the StorageClass

For importing:	
1. Both `bandwidth_limit` and `iops_limit` parameters are passed in as properties under `volumeAttributes` in PVs. 

## Restrictions
* Both parameters must be passed as string types, i.e., they need to have double quotation marks around them. See examples below.
* If the iops limit is set, it must be between 100 and 100 million. 
* If the bandwidth limit is set, it must be between 1 MB/s and 512 GB/s. Enter the size as a number (bytes) or number with a single character unit symbol. Valid unit symbols are K, M, G, representing KiB, MiB, and GiB, respectively, where "Ki" denotes 2^10, "Mi" denotes 2^20, and so on. If the unit symbol is not specified, the unit defaults to bytes and must be between 1048576 and 549755813888 and must be multiple of 512. 


## Example - new volume and cloning
1. Create a new StorageClass

    Here is an example, but more examples can be found [here](../pure-csi/templates):
    
    `pure-block-gold` StorageClass is defined with an IOPS limit of 30k and bandwidth limit of 10GB/s, for workloads that require high storage throughput.
    
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: pure-block-gold
      labels:
        kubernetes.io/cluster-service: "true"
    provisioner: pure-csi
    parameters:
      #TODO: choose limits
      iops_limit: "30000"
      bandwidth_limit: "10G"
      backend: block
      csi.storage.k8s.io/fstype: xfs
      createoptions: -q
    allowVolumeExpansion: true
    ```
    
    `pure-block-bronze` StorageClass is defined with lower IOPS and bandwidth limit for workloads with lower storage throughput requirements.
    
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: pure-block-bronze
      labels:
        kubernetes.io/cluster-service: "true"
    provisioner: pure-csi
    parameters:
      #TODO: choose limits
      iops_limit: "3000"
      bandwidth_limit: "1G"
      backend: block
      csi.storage.k8s.io/fstype: xfs
      createoptions: -q
    allowVolumeExpansion: true
    ```

2. Create and deploy a Persistent Volume Claim object with the StorageClass name configured to the StorageClass created at step 1

   Here is an example, but more examples can be found at [here](./examples):

    ```yaml
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: test-pvc-qos
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi
      storageClassName: pure-block-gold
    ```

    To apply:
    
    ```
    kubectl apply -f {PVC_yaml_file_name}
    ```
## Example - importing
For full documentation of importing, please see [here](/docs/csi-volume-import.md), and examples [here](./examples/volumeimport).

To impose QoS limits during importing, since the volume to be imported already exists, simply add the QoS parameters in the `PersistentVolume`under `VolumeAttributes`, other steps as shown in the importing doc remain the same. 
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: pure-csi
  name: pv-import
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    # TODO: change to the PVC you want to bind this PV.
    # If you don't pre-bind PVC here, the PV might be automatically bound to a PVC by scheduler.
    name: pvc-import
    # Namespace of the PVC
    namespace: default
  csi:
    driver: pure-csi
    # TODO: change to the volume name in backend.
    # Volume with any name that exists in backend can be imported, and will not be renamed.
    volumeHandle: ttt-pvc-a90d7d5f-da6c-44db-a306-a4cc122f9dd3
    volumeAttributes:
        bandwidth_limit: "2G"
        iops_limit: "99999"
      backend: file
  # TODO: configure your desired reclaim policy,
  # Use Retain if you don't want your volume to get deleted when the PV is deleted.
  persistentVolumeReclaimPolicy: Delete
  storageClassName: pure-file
  volumeMode: Filesystem
```
The QoS only gets applied when the volume is being used by a pod. Again please make sure both parameters are passed in as strings. 
## Validation

After a PVC is created it will be bound to a new FlashArray based Persistent Volume with QoS limits set. To verify the QoS limits are set correctly, please use the following steps:
    
   1. Run `kubectl get pvc` to make sure your volume is bound and obtain the volume name.
   2. From the FlashArray GUI to see the volumes QoS settings.
      Go to Storage -> Volumes, search for the volume just created and the QoS attributes are shown at the bottom of the screen. 
    
   **Note:** This feature applies QoS limits at volume-creation time for new volume provisioning and cloning, and volume utilization time for importing. But both bandwidth and IOPS limit can be modified at any time afterwards through the FlashArray UI or the REST API `PUT Volume` call - see the API guide for details.
   Additionally, QoS settings for volumes may be modified using the Pure Storage FlashArray Ansible module [`purefa_volume`](https://github.com/Pure-Storage-Ansible/FlashArray-Collection/blob/master/collections/ansible_collections/purestorage/flasharray/plugins/modules/purefa_volume.py).
