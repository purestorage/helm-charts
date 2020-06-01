# Using StorageClasses with Pure Service Orchestrator

***NOTE THAT THIS ONLY APPLIES TO THE CSI VERSION OF PSO***

PSO creates persistent volumes within the federated storage pool of backend appliances defined using criteria defined in the `StorageClass` used to request the persistent volume.

## What is a `StorageClass`

A `StorageClass` allow administrators to define various storage configurations to provide high availability, serve quality-of-service requirements, tune file system options, define backup policies, and more. PSO utilizes these storage classes to decide where to provision volumes and how to make the file system.

For more information on `StorageClass` go [here](https://kubernetes.io/docs/concepts/storage/storage-classes/)

## Provided Storage Classes

As part of the installation of PSO, three storage classes are created which can be used to simply create persistent volumes on a file or a block backend device within the federated storage pool using all the default settings PSO has provided.

Two of these are called `pure-file` and `pure-block` and, as their names suggest, they will create persistent volumes from the block providing or file providing backends within the federated pool of backend devices. At all times the load-balancing algorithm within PSO will ensure that the persistent volume is created on the most appropriate backend given the block or file requirement, even if there are multiple block or file providing appliances in the pool.

The third `StorageClass` is simply called `pure`. This is provided primarily as a legacy class to provide backwards capability with early PSO releases. By default this storage class uses block storage appliances to provision block-based persistent volumes, however, this can be modified in the PSO configuration `values.yaml`.

## Default `StorageClass`

Within the PSO configuration file is a setting to enable the `pure` `StorageClass` as the default class for the Kubernetes cluster. To enable `pure` as the default class set the following parameter in `values.yaml`

```yaml
  storageClass:
    isPureDefault: true
```

As mentioned above, the `pure` class uses block-based backend appliances to provision persistent volumes from. It is possible to change this default setting to use file-backed appliances from the pool.

You may wish to do this if you only have FlashBlades in your PSO configuration, as these can only provide file-based persistent volumes.

To change the backend type used by the `pure` `StorageClass` to file rather than block, change the following line within the values.yaml configuration file:

```yaml
  pureBackend: file
```

## Creating your own Storage Classes for PSO to use

With the increasing options available to configure the persistent volumes supported by PSO it may be necessary to create additional storage classes that will use PSO to provide specific configurations of persistent volume.

For example, if you wish to provide raw block volumes (shortly to be supported by PSO) then you will need to request these from a `StorageClass` that knows how to do this. Alternatively, you may have a requirement for some block-based persistent volumes to be formatted with the `btfs` file system rather than the default `xfs` file system provided by PSO through the `pure-block` `StorageClass`, or the default Kubernetes filesystem of `ext4`

[**NOTE:** Pure does not recommend using `ext4` as a filesystem for persistent volumes in containers]

With the addition of [per volume filesystem options](csi-filesystem-options.md), the ability to use a different `StorageClass` for different requirements becomes critical.

To create a storageClass that will use PSO use the following template and modify as required for your custom storage class.

```yaml
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: <your storageClass name>
    labels:
      kubernetes.io/cluster-service: "true"
  provisioner: pure-csi
  parameters:
```

Within the `parameters` section is where you add your own custom settings. More details of some of the options available to use in the parameters section can be found [here](csi-filesystem-options.md)

Once you have created your `StorageClass` definition in a YAML file, create it in Kubernetes using the command

```bash
kubectl apply -f <storageclassdefinition>.yaml
```

If you wish to ensure your new `StoraegClass` is the default class then add the following into the metadata section of the definition:

```yaml
  annotations:
    storageclass.kubernetes.io/is-default-class: true
```

**NOTE:** if a `StorageClass` is already flagged as default your new `StorageClass` will not take its place, but you will have multiple default storage classes. In this case Kubernetes will completely ignore the default flags and you may fail to create the persistent volumes you expected.

