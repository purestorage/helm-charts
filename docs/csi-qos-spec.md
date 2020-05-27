# Apply Qos control on storageclass level

## Use Cases
- Users want to set bandwidth limit for their volumes
- Users want to set IOPS limit for their volumes

## Dependencies
* Pure CSI driver 6.0.0+ 
* Purity Version 5.3.0+ (Public API version 1.17 +)
* Support FlashArray block storage only

## General guidance
Qos allows users to impose QoS limits on their persistent volumes created and managed by PSO on Kubernetes clusters. Whenever throughput exceeds the limit specified, throttling occurs. Specifically, we enable users to specify their bandwidth limit in terms of volume capacity per second and Input/Output per second. Users can opt to enable one or the other, or both. The two parameters are passed in through parameter fields in storageclasses. The feature is only supported on FlashArray block storage. 

At volume provision time:
1. If the user does not own any FlashArray that supports QoS (5.3 and above), the volume will NOT be provisioned successfully. 
2. If the user owns multiple devices, PSO will look for the FlashArray that supports QoS and provision the volume on that device. If multiple arrays support QoS, the existing algorithm is leveraged to determine the array to provision the volume. 
3. To enable bandwidth limit

    add `bandwidth_limit` as a parameter in storageclass

4. To enable IOPS limit

    add `iops` as a parameter in storageclass

## Restrictions
* Both parameters must be passed in as string types, i.e., they need to have double quotation marks around them, see examples in the later section.
* If the bandwidth limit is set, it must be between 1 MB/s and 512 GB/s. Enter the size as a number (bytes) or number with a single character unit symbol. Valid unit symbols are K, M, G, T, P, representing KiB, MiB, GiB, TiB, and PiB, respectively, where "Ki" denotes 2^10, "Mi" denotes 2^20, and so on. If the unit symbol is not specified, the unit defaults to bytes. And when no unit symbol is used, the number entered must be multiple of 512. 


 
## Example
1. **Verify that user devices support QoS**
    * In the UI, check the API guide under Help -> REST API Guide
If the REST API version shown is above 1.17, QoS is supported.
    * Or in command line, execute the following curl command:
        ```bash
        GET https://{deviceIP}/api/api_version
        ```
        A list of REST API versions supported is returned, if 1.17 and above present in the list, QoS is supported

2. **Create a new storageclass**

    Here is an example, but more examples can be found at: [pure-csi/templates](../pure-csi/templates)
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: gold
      labels:
        kubernetes.io/cluster-service: "true"
    provisioner: pure-csi # This must match the name of the CSIDriver. And the name of the CSI plugin from the RPC 'GetPluginInfo'
    parameters:
      iops_limit: "99999"
      bandwidth_limit: "200G"
      backend: block
      csi.storage.k8s.io/fstype: xfs
      createoptions: -q
    allowVolumeExpansion: true
    ```

    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: bronze
      labels:
        kubernetes.io/cluster-service: "true"
    provisioner: pure-csi # This must match the name of the CSIDriver. And the name of the CSI plugin from the RPC 'GetPluginInfo'
    parameters:
      #TODO: choose limit
      iops_limit: "9999"
      bandwidth_limit: "2G"
      backend: block
      csi.storage.k8s.io/fstype: xfs
      createoptions: -q
    allowVolumeExpansion: true
    ```

3. **Create and deploy a persistent volume claim object with storageclass name configured to the storageclass created at step 1**

   Here is an example, but more examples can be found at: [examples](./examples)

    ```yaml
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      # Referenced in pod.yaml for the volume spec
      # TODO: choose name for PVC
      name: testingPVC
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi
      # TODO: Matches the name defined in deployment/storageclass.yaml
      storageClassName: gold # need to be same as storageclass name
    ```

    To apply:
        ```
        kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/topology/pvc-delay-binding.yaml
        ```
    To see if the volume bound successfully. 

    run ```kubectl get pvc```, grab the volume name. QoS setting can be tracked in two ways
    1. through the command line
            ```
            GET https://{deviceIP}}/api/{api_version}}/volume/{volume_name}}?qos=true
            ```
    2. through the dashboard UI. 
    go to Storage -> Volumes, search for the volume just created and QoS is shown at the bottom. 

**Note** that this feature applies QoS limits at volume creation time, but both bandwidth_limit and IOPS can be modified at any time after volume creation either through the UI or REST API Put Volume command, see API guide for detail.




