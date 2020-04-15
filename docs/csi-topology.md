# Using CSI Topology-Aware Volume Provisioning with Kubernetes

## Introduction

The Pure Service Orchestrator Kubernetes CSI driver includes support for storage topology. This feature allows Kubernetes to make intelligent decisions when dynamically provisioning volumes by getting scheduler input on the best place to provision a volume for a pod.
For example, in multi-zone clusters, volumes will get provisioned in an appropriate zone that can run your pod, allowing you to quickly deploy and scale your stateful workloads to provide high availability and better fault tolerance.

It also allows topology to be further specified or constrained for both pre-provisioned and dynamically provisioned PersistentVolumes (PV) so that the Kubernetes scheduler can correctly place a Pod using such a volume to an appropriate node.
  

## Dependencies

The following dependencies must be true before the storage topology functionality can be used:

* Kubernetes already running, deployed, configured, etc
* PSO correctly installed and using [Pure CSI Driver v5.1.0](https://github.com/purestorage/helm-charts/releases/tag/5.1.0)+.
* Ensure you have Kubernetes 1.13+ installed, if you are using a version less than 1.13, please make sure the `VolumeScheduling` feature gate is enabled

## Caveats
* Please make sure your backend arrays support all topologies defined in your system. Failing to do so will potentially leak volumes.
  PSO follows the [CSI Spec](https://github.com/container-storage-interface/spec/blob/master/spec.md) to do its best effort to provision a volume with all possible topologies specified by the scheduler.
For example, if you want to provision a pod to be in `region-2` by assigning the topology via `nodeAffinity`, the scheduler will ask PSO to provision a volume with the topology order like this [`region-2` , `region-1`, `region-0`]. In this case, if your arrays don't support `region-2`, PSO ends up to provision the volume in one of the remaining regions [`region-1`, `region-0`].
The scheduler will end up failing to provision the pod because the volume's topology does not match the pod's requirement. Although this is expected behavior, it leaks the unexpected volume, and you need to delete it manually.

## How to Use The Topology-Aware Provisioning Feature in PSO
There are two parameters in the `values.yaml` to enable/disable the CSI topology :
```yaml
storagetopology:
  enable: false
  strictTopology: false
```
`enable` controls enable/disable the CSI topology and `storagetopology` sets  the [strict-topology feature](https://github.com/kubernetes-csi/external-provisioner/blob/master/README.md#topology-support) when users need it. 
 They are set to `false` by default. You need to set the parameters to `true` to enable the feature.

It is straightforward to use the topology feature in PSO. PSO provides users a pre-defined **pure topology key prefix** (`topology.purestorage.com/`) to label any topology segments you want.
You can define your topology key/value pairs like these:

```yaml
topology.purestorage.com/foo : "foo"
topology.purestorage.com/bar : "bar"

```
or more formal cloud-hierarchical ways: 
```yaml
topology.purestorage.com/zone : "zone-0"
topology.purestorage.com/region : "region-0"
```


### Example of Adding Topology Labels to Arrays
To add topology labels to your backend array, please add them in the `Labels` section of you `values.yaml` file.

```yaml
FlashArrays:
     # fs59-20
     - MgmtEndPoint: "20.0.0.1"
       APIToken: ""
       Labels:
         topology.purestorage.com/zone : "zone-0"
         topology.purestorage.com/region : "region-0"
         topology.purestorage.com/env: "dev"
     # fs59-21
     - MgmtEndPoint: "10.0.0.2"
       APIToken: ""
       Labels:
         topology.purestorage.com/zone : "zone-1"
         topology.purestorage.com/region : "region-1"
         topology.purestorage.com/env: "dev"
   FlashBlades:
     # c14-59d-36-irp
     - MgmtEndPoint: "10.0.0.2"
       APIToken: ""
       NFSEndPoint: ""
       Labels:
         topology.purestorage.com/zone: "zone-0"
         topology.purestorage.com/region: "region-0"
         topology.purestorage.com/env: "dev"
``` 

### Example of Labeling Topology to Cluster Nodes

```bash
kubectl label node k8s-cluster-0 topology.purestorage.com/zone=zone-1
kubectl label node k8s-cluster-0 topology.purestorage.com/region=region-1
kubectl label node k8s-cluster-0 topology.purestorage.com/env=dev
``` 
**NOTE:** PSO supports dynamic topology labeling. It allows users to add/remove topology labels of cluster nodes on the fly without reloading the PSO. However, users still need to update the `values.yaml` and reload the driver if you want to change the backend array topologies.

## Delayed Volume Binding
Without the topology-aware feature, volume binding occurs immediately once a PersistentVolumeClaim is created. For volume binding to take into account all of a pod’s other scheduling constraints, volume binding must be delayed until a Pod is being scheduled.

A new StorageClass field `volumeBindingMode` is introduced to control the volume binding behavior.
You can specify two values:

* `Immediate`: This the default binding method. External-provisioner will pass in all available topologies in the cluster for the driver.
* `WaitForFirstConsumer`: external-provisioner will wait for the scheduler to pick a node. The topology of that selected node will then be set as the first entry in `CreateVolumeRequest.accessibility_requirements.preferred`. All remaining topologies are still included in the requisite and preferred fields to support storage systems that span across multiple topologies.

### Example of StorageClass with Delayed Volume Binding 
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: pure-block-delay-binding
  labels:
    kubernetes.io/cluster-service: "true"
    chart: pure-csi
    release: "pure-storage-driver"
provisioner: pure-csi 
volumeBindingMode: WaitForFirstConsumer
parameters:
    backend: block
```
To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/topology/pure-block-delay-binding.yaml
```
### Example of PVC using Delay Binding StorageClass
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  # Referenced in pod.yaml for the volume spec
  name: pure-delay-binding
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # Matches the name defined in deployment/storageclass.yaml
  storageClassName: pure-block-delay-binding
```
To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/topology/pvc-delay-binding.yaml
```
Once you apply the delay-binding PVC yaml, you should see the PVC is in pending state and wait for the scheduler for further signal.
```
NAME                STATUS    VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS               AGE       VOLUMEMODE
pure-delaybinding   Pending                                       pure-block-delay-binding   14s       Filesystem
```

## Example of using allowedTopologies in StorageClass

When you specify the `WaitForFirstConsumer` volume binding mode in the `StorageClass`, it is no longer necessary to restrict provisioning to specific topologies in most situations. However, if still required, `allowedTopologies` can be specified.
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: pure-block-restrict-provisioning
provisioner: pure-csi
parameters:
    backend: block
allowedTopologies:
  - matchLabelExpressions:
      - key: topology.purestorage.com/rack
        values:
          - rack-0
          - rack-1
```
To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/topology/pure-block-restrict-provisioning.ymal
```

### Example of POD with NodeAffinity
In this pod yaml example, it specifies the `nodeAffinity` to assign Pod to be hosted in any nodes that label `region-0`. 
Thus, the delay binding PV will also be enforced and bind at the same node. 
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-delay-binding
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.purestorage.com/region
            operator: In
            values:
            - region-0
  # Specify a volume that uses the claim defined in pvc.yaml
  volumes:
  - name: pure-vol
    persistentVolumeClaim:
        claimName: pure-delay-binding
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
To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/topology/pod-delay-binding.yaml
```
This example demonstrates how to restrict the topology of provisioned volumes to specific zones and should be used as a replacement for the zone and zones parameters for the supported plugins.
## Example of StatefulSet For High Availability
The following example demonstrates multiple pod constraints and scheduling policies along with topology-aware volume provisioning.
In the example, we use `volumeClaimTemplates` to specifies the StorageClass that supports the delayed binding that we provision and bind volumes at runtime to achieve high availability.
The scheduler will even distribute pods and volumes among `region-0` and `region-1`.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  replicas: 4
  selector:
    matchLabels:
      app: nginx
  serviceName: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              -
                matchExpressions:
                  -
                    key: topology.purestorage.com/region
                    operator: In
                    values:
                      - region-0
                      - region-1
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            -
              labelSelector:
                matchExpressions:
                  -
                    key: app
                    operator: In
                    values:
                      - nginx
              topologyKey: failure-domain.beta.kubernetes.io/zone
      containers:
        - name: nginx
          image: gcr.io/google_containers/nginx-slim:0.8
          ports:
            - containerPort: 80
              name: web
          volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
            - name: logs
              mountPath: /logs
  volumeClaimTemplates:
    - metadata:
        name: www
      spec:
        accessModes: [ "ReadWriteOnce" ]
        storageClassName: pure-block-delay-binding
        resources:
          requests:
            storage: 5Gi
    - metadata:
        name: logs
      spec:
        accessModes: [ "ReadWriteOnce" ]
        storageClassName: pure-block-delay-binding
        resources:
          requests:
            storage: 1Gi
```
To apply:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/helm-charts/master/docs/examples/topology/statefulset-topology.yaml
```
