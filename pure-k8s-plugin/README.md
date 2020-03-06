# pure-k8s-plugin

This helm chart installs the FlexVolume plugin on a Kubernetes cluster.

## Platform and Software Dependencies
- #### Operating Systems Supported*:
  - CentOS 7
  - RHEL 7
  - CoreOS (Ladybug 1298.6.0 and above)
  - Ubuntu 16.04
  - Ubuntu 18.04
- #### Environments Supported*:
  - Kubernetes 1.6+
  - Helm 2.9.1+ (**NOTE:** Helm3 is not supported for FlexDriver)
  - [OpenShift](#openshift) 3.11
  - AWS EKS 1.14
- #### Other software dependencies:
  - Latest linux multipath software package for your operating system (Required)
  - Latest Filesystem utilities/drivers (XFS by default, Required)
  - Latest iSCSI initiator software for your operating system (Optional, required for iSCSI connectivity)
  - Latest NFS software package for your operating system (Optional, required for NFS connectivity)
  - Latest FC initiator software for your operating system (Optional, required for FC connectivity, *FC Supported on Bare-metal K8s installations only*)
- #### FlashArray and FlashBlade:
  - The FlashArray and/or FlashBlade should be connected to the compute nodes using [Pure's best practices](https://support.purestorage.com/Solutions/Linux/Reference/Linux_Recommended_Settings)

_* Please see release notes for details_

## How to install

Add the Pure Storage helm repo

```bash
helm repo add pure https://purestorage.github.io/helm-charts
helm repo update
helm search repo pure-k8s-plugin
```

Optional (offline installation): Download the helm chart

```bash
git clone https://github.com/purestorage/helm-charts.git
```

Create your own `values.yaml` and install the helm chart with it, and keep it. The easiest way is to copy
the default [./values.yaml](./values.yaml)

### Configuration

The following table lists the configurable parameters and their default values.

|             Parameter       |            Description             |                    Default                |
|-----------------------------|------------------------------------|-------------------------------------------|
| `image.name`                | The image name       to pull from  | `purestorage/k8s`                         |
| `image.tag`                 | The image tag to pull              | `2.5.8`                                   |
| `image.pullPolicy`          | Image pull policy                  | `Always`                                  |
| `app.debug`                 | Enable/disable debug mode for app  | `false`                                   |
| `storageclass.isPureDefault`| Set `pure` storageclass to the default | `false`                               |
| `storageclass.pureBackend`  | Set `pure` storageclass' default backend type | `block`                               |
| `clusterrolebinding.serviceAccount.name`| Name of K8s/openshift service account for installing the plugin | `pure`                    |
| `flasharray.defaultFSType`  | Block volume default filesystem type. *Not recommended to change!* | `xfs`     |
| `flasharray.defaultFSOpt`  | Block volume default mkfs options. *Not recommended to change!* | `-q`          |
| `flasharray.defaultMountOpt`  | Block volume default filesystem mount options. *Not recommended to change!* |     ""    |
| `flasharray.iSCSILoginTimeout`  | iSCSI login timeout in seconds. *Not recommended to change!* |     `20sec`    |
| `flasharray.iSCSIAllowedCIDR`  | List of CIDR blocks allowed as iSCSI targets, e.g. 10.0.0.0/24,10.1.0.0/16. Use comma (,) as the separator, and empty string means allowing all addresses. |     ""    |
| `flasharray.preemptAttachments`  | Enable/Disable attachment preemption! |     `true`    |
| `flasharray.sanType`        | Block volume access protocol, either ISCSI or FC | `ISCSI`                     |
| `flashblade.snapshotDirectoryEnabled`  | Enable/Disable FlashBlade snapshots |     `false`    |
| `namespace.pure`            | Namespace for the backend storage  | `k8s`                                     |
| `orchestrator.name`         | Orchestrator type, such as openshift, k8s | `k8s`                              |
| `flexPath`                  | Full path of directory to install flex plugin, works with image.tag >= 2.0.1 | `/usr/libexec/kubernetes/kubelet-plugins/volume/exec` |
| *`arrays`                    | Array list of all the backend FlashArrays and FlashBlades | must be set by user, see an example below                |
| `nodeSelector`              | *Deprecated* Use `flexDaemon.nodeSelector` and `provisioner.nodeSelector` instead. | `{}` |
| `tolerations`               | *Deprecated* Use `flexDaemon.tolerations` and `provisioner.tolerations` instead | `[]` |
| `affinity`                  | *Deprecated* Use `flexDaemon.affinity` and `provisioner.affinity` instead | `{}` |
| `flexDaemon.nodeSelector`              | [NodeSelectors](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) Select node-labels to schedule flex-plugin. See [this](https://docs.openshift.com/container-platform/3.11/admin_guide/managing_projects.html#using-node-selectors) for setting node selectors on Openshift. | `{}` |
| `flexDaemon.tolerations`               | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/#concepts)  | `[]` |
| `flexDaemon.affinity`                  | [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) | `{}` |
| `provisioner.nodeSelector`              | [NodeSelectors](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) Select node-labels to schedule provisioner. See [this](https://docs.openshift.com/container-platform/3.11/admin_guide/managing_projects.html#using-node-selectors) for setting node selectors on Openshift. | `{}` |
| `provisioner.tolerations`               | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/#concepts)  | `[]` |
| `provisioner.affinity`                  | [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) | `{}` |

*Examples:
```yaml
arrays:
  FlashArrays:
    - MgmtEndPoint: "1.2.3.4"
      APIToken: "a526a4c6-18b0-a8c9-1afa-3499293574bb"
      Labels:
        rack: "22"
        env: "prod"
    - MgmtEndPoint: "1.2.3.5"
      APIToken: "b526a4c6-18b0-a8c9-1afa-3499293574bb"
  FlashBlades:
    - MgmtEndPoint: "1.2.3.6"
      APIToken: "T-c4925090-c9bf-4033-8537-d24ee5669135"
      NfsEndPoint: "1.2.3.7"
      Labels:
        rack: "7b"
        env: "dev"
    - MgmtEndPoint: "1.2.3.8"
      APIToken: "T-d4925090-c9bf-4033-8537-d24ee5669135"
      NfsEndPoint: "1.2.3.9"
      Labels:
        rack: "6a"
```

## Assigning Pods to Nodes

It is possible to make flex-daemon and provisioner run on specific nodes
using `nodeSelector`, `toleration` and `affinity`. You can set these config
separately for flex-daemon and provisioner (e.g. `flexDaemon.nodeSelector`).
The unprefixed parameters have been deprecated but will still be used as a
fallback if the prefixed parameters are not set. (e.g. if `nodeSelector` is
set but `provisioner.nodeSelector` is not, provisioner will use the value of
`nodeSelector` as a fallback) This makes sure the behavior is backward
compatible.

## Install the plugin in a separate namespace (i.e. project)

For security reason, it's strongly recommended to install the plugin in a separate namespace/project. Make sure the namespace is existing, otherwise create it before installing the plugin.

Customize your values.yaml including arrays info (replacement for pure.json), and then install with your values.yaml.

Dry run the installation, and make sure your values.yaml is working correctly:

```bash
helm install pure-storage-driver pure/pure-k8s-plugin --namespace <namespace> -f <your_own_dir>/yourvalues.yaml --dry-run --debug
```

**Run the Install:**

```bash
# For Openshift 3.11 only:
#   you need to add the privileged securityContextConstraints (scc) to the service account which is created for plugin installation.
#   You can find the serviceaccount info from your values.yaml (if not in it, find in the default values.yaml).
#   The service account should be "system:serviceaccount:<project>:<clusterrolebinding.serviceAccount.name>"
oc adm policy add-scc-to-user privileged system:serviceaccount:<project>:<clusterrolebinding.serviceAccount.name>

# Install the plugin (works for both openshift and kubernetes)
helm install pure-storage-driver pure/pure-k8s-plugin --namespace <namespace> -f <your_own_dir>/yourvalues.yaml
```

The values in your `values.yaml` overwrite the ones in `pure-k8s-plugin/values.yaml`, but any specified with the `--set` option will take precedence.

```bash
helm install pure-storage-driver pure/pure-k8s-plugin --namespace <namespace> -f <your_own_dir>/yourvalues.yaml \
            --set flasharray.sanType=fc \
            --set namespace.pure=k8s_xxx \
            --set orchestrator.name=openshift
```

## How to update `arrays` info

Update your values.yaml with the correct arrays info, and then upgrade the helm as below.

**Note**: Ensure that the values for `--set` options match when run with the original install step. It is highly recommended
to use the values.yaml and not specify options with `--set` to make this easier.

```bash
helm upgrade pure-storage-driver pure/pure-k8s-plugin --namespace <namespace> -f <your_own_dir>/yourvalues.yaml --set ...
```

# Using Snapshots with a FlashArray

More details on using the snapshot functionality can be found [here](../docs/flex-snapshot-for-flasharray.md)

# Using Labels to control volume topology

More details on using configuration labels can be found [here](../docs/flex-volume-using-labels.md)

# Upgrading
## How to upgrade the driver version

It's not recommended to upgrade by setting the `image.tag` in the image section of values.yaml. Use the version of
the helm repository with the tag version required. This ensures the supporting changes are present in the templates.

```bash
# list the avaiable version of the plugin
helm repo update
helm search repo pure-k8s-plugin -l

# select a target chart version to upgrade as
helm upgrade pure-storage-driver pure/pure-k8s-plugin --namespace <namespace> -f <your_own_dir>/yourvalues.yaml --version <target chart version>
```

## How to upgrade from the legacy installation to helm version

This upgrade will not impact the in-use volumes/filesystems from data path perspective. However, it will affect the in-flight volume/filesystem management operations. So, it is recommended to stop all the volume/filesystem management operations before doing this upgrade. Otherwise, these operations may need to be retried after the upgrade.

1. Uninstall the legacy installation using the install script provided as `./install.sh --uninstall`.
2. Reinstall via helm<br/>
    a. Convert `pure.json` into the `arrays` info in your `values.yaml` (online tool: https://www.json2yaml.com/).
3. Ensure `flexPath` match up exactly with kubelet's `volume-plugin-dir` parameter.<br/> 
    a. How to find the full path of the directory for pure flex plugin (i.e. `volume-plugin-dir`) 
    ```bash
    # ssh to a node which has pure flex plugin installed, and check the default value of "volume-plugin-dir" from "kubelet --help"
    # and then find the full path of the directory as below:

    # for k8s
    root@k8s-test-k8s-0:~# find /usr/libexec/kubernetes/kubelet-plugins/ -name "flex" | xargs dirname
    /usr/libexec/kubernetes/kubelet-plugins/volume/exec/pure~flex

    # for openshift on RHEL Server
    root@k8s-test-openshift-0:~# find /usr/libexec/kubernetes/kubelet-plugins/ -name "flex" | xargs dirname
    /usr/libexec/kubernetes/kubelet-plugins/volume/exec/pure~flex
    
    # for openshift 3.10+ on RHEL Atomic
    root@k8s-test-openshift-0:~# find /etc/origin/kubelet-plugins/ -name "flex" | xargs dirname
    /etc/origin/kubelet-plugins/volume/exec/pure~flex
    ```

## Containerized Kubelet

If Kubernetes is deployed using containerized kubelet services then there
may be steps required to ensure it can use the FlexVolume plugin. In general
there are a few requirements that must be met for the plugin to work.

### Requirements

The container running the kubelet service must have:

* Access to the host systems PID namespace
* Access to host devices and sysfs (`/dev` & `/sys`)
* Access to the kubelet volume plugin directory

For the volume plugin directory this defaults to `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`
but can be adjusted with the kubelet `volume-plugin-dir` option. Where
possible the containerized kubelet should have this directory passed in from
the host system.

To change the volume plugin directory a few steps are required:

* Update the kubelet service to use the `volume-plugin-dir` option, and
  direct it to the new location.
* Ensure the kubelet container is configured to mount the new location
  into the container.
* Ensure that the `pure-flex-daemon.yaml` is configured to to use the
  new plugin directory for the `kubelet-plugins` host volume mount.

This allows for the `pure-flex` plugin to be installed in the new location
on the filesystem, and for the kubelet to have access to the plugin.

## Platform Specific Considerations

Some Kubernetes environments will require special configuration, especially
on restrictive host operating systems where parts of it are mounted read-only.

### Atomic

Atomic is configured to have the `/usr` directory tree mounted
as read-only. This will cause problems installing the `pure-flex` plugin
as write permission is required.

To get things working an alternate plugin directory should be used, a
good option is `/etc/kubernetes/volumeplugins/`. This is convienient for
both because it is writable, and the kubelet container will already be
mounting the `/etc/kubernetes/` directory in to the kubelet.

Once changed the kublet parameters need to be updated to set the
`volume-plugin-dir` to be `/etc/kubernetes/volumeplugins/`, and the
`pure-flex` DaemonSet needs to be adjusted to install there as well
via the `flexPath` option in your `values.yaml`.

### CoreOS

Similar to the Atomic hosts this has a read-only `/usr` tree and requires
the plugin to be installed to an alternate location. Follow the same
recommendations to use `/etc/kubernetes/volumeplugins/` and adjust
the kubelet service to use the `--volume-plugin-dir` CLI argument and
mount the `/etc/kubernetes` directory into the container.

### OpenShift

Specify the `orchestrator.name` to be `openshift` and configure the other
OpenShift specific options.

**Note: the deployment is done with the default service account,
and requires privileged containers. This means you may need to modify
the service account used to use a new or existing service account with
the right permissions or add the privileged scc to the default service
account.**

### OpenShift Containerized Deployment

When deploying OpenShift with the containerized deployment method it is
going to require mounting the plugin directory through to the container
running the kubelet service.

The kubelet configuration is then set via the `node-config.yaml` in the
`kubeletArguments` section to set the `volume-plugin-dir`. The easiest
path to use is something like `/etc/origin/kubelet-plugins` or similar
as the node config path is passed through to the container.

# Release Notes

Release notes can be found [here](https://github.com/purestorage/helm-charts/releases)

### Known Vulnerabilities 

None

# License

https://www.purestorage.com/content/dam/pdf/en/legal/pure-storage-plugin-end-user-license-agreement.pdf
