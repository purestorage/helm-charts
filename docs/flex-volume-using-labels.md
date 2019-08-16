# Using Labels with the FlexVolume Driver

## Introduction
The Pure Service Orchestrator Kubernetes FlexVolume driver includes the capability to provision volumes with storage backend and node requirements using **label selectors**.  Labels can be added to each FlashArray or FlashBlade with the
main `values.yaml` configuration file.
These **labels** are completely customizable and can be any key-value-pair required by the cluster administrator.
There can be as many labels as required, there can be no labels, and different arrays can share the same labels. The world is your oyster!

## Example configuration
Here is an example of how to configure **labels** in a `values.yaml` configuration file for two FlashArrays:
```yaml
arrays:
  FlashArrays:
    - MgmtEndPoint: "xx.xx.xx.xx"
      APIToken: "3863412d-c8c9-64be-e7f5-1ef8b4d7b221"
      Labels:
        rack: 33
        user: prod
    - MgmtEndPoint: "yy.yy.yy.yy"
      APIToken: "e0770d27-adfd-a46b-42fa-0c3ebb5e4356"
      Labels:
        rack: 34
        user: prod
```

In this example we can see that each array has two labels. One label, `user`, is common to the two arrays, and the other, `rack`, is unique to each array.

## Using **labels**

The `label` definition can be used by selectors in your persistent volume claim (PVC) template. This can then be expanded to limit the
worker nodes that can actually use these PVCs using the concept of node affinity. These constructs can help you manage the topology of your persistent storage.

### PV Topology and Affinity Control
To create a PV on a specific array, or within a group of backend arrays, the PVC definition must contain the following with the `spec:` section of the PVC template:
```yaml
spec:
  selector:
        matchExpressions:
        - key: user
          operator: In
          values: ["prod"]
```
This example ensures that the PV is created by PSO on an array with the `user: prod` key-value pair. If there are multiple arrays with this label, PSO will load balance
across only those arrays to determine the most appropriate location for the PV.

Additionally, PVs can be limited to only allow access by specific worker nodes using the concept of Node Affinity. This node affinity can be limited to an
indiviual node, or a group (or zone) of nodes.

See the following examples:

1. Limiting a PV to a specific worker node
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  Name: pure-volume-1
spec:
  capacity:
    storage: 100Gi
  storageClassName: pure-block
  local:
    path: /data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node-1
```
2. Limiting to a group (or zone) of nodes (in this case to nodes labeled as being in Rack 33)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  Name: pure-volume-1
spec:
  capacity:
    storage: 100Gi
  storageClassName: pure-block
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: failure-domain.beta.kubernetes.io/zone
          operator: In
          values:
          - rack-33
```
3. Limiting to any worker node in one or more zones
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  Name: pure-volume-1
spec:
  capacity:
    storage: 100Gi
  storageClassName: pure-block
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: failure-domain.beta.kubernetes.io/zone
          operator: In
          values:
          - rack-33
          - rack-34
```
To ensure that these `nodeAffinity` rules are understood, it is necessary to correctly label your worker nodes:
```bash
kubectl label node prod01 failure-domain.beta.kubernetes.io/zone="rack-33"
kubectl label node prod02 failure-domain.beta.kubernetes.io/zone="rack-33"
kubectl label node prod03 failure-domain.beta.kubernetes.io/zone="rack-34"
kubectl label node prod04 failure-domain.beta.kubernetes.io/zone="rack-34"
```
Additonally, you can control a specific application to use only worker nodes and PVs located in the same rack.
An example of this would be where applications need their persistent storage to be close to the worker node running the application, such as an application 
that must run on a GPU-enabled node and needs its PVs to have the minimal separation to reduce latency. This can be achieved by ensuring the application
deployment template contains the `selector` labels in the PVC definition section (as shown above) and the following (example) code in the Pod definiton section:
```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                - key: "failure-domain.beta.kubernetes.io/zone"
                  operator: In
                  values: ["rack-33"]
```
With some creative scripting of deployment templates it would even be possible to create a disaster tolerant deployment of an application such as MongoDB
that controls its own data replication using replica pods, by ensuring that each replica node is deployed to a different zone/rack and that the
persistent storage for that replica is only provided from a storage array in the same rack. This will give tolerance over an entire rack failing,
with no data loss for the application, because the array in the failed rack is not providing storage to a replica in another rack.
