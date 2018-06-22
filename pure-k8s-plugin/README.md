# pure-k8s-plugin

## Version restrictions

Minimum Helm version required is 2.9.1
Minimum version of K8S FlexVol driver required is 2.0.0

## How to install

Add the Pure Storage helm repo
```
helm repo add pure https://purestorage.github.io/helm-charts
helm repo update
helm search pure-k8s-plugin
```

Optional (offline installation): Download the helm chart
```
git clone https://github.com/purestorage/helm-charts.git
```

Create your own values.yaml and install the helm chart with it, and keep it. Easiest way is to copy
the default [./values.yaml](./values.yaml)

### Configuration

The following table lists the configurable parameters and their default values.

|             Parameter       |            Description             |                    Default                |
|-----------------------------|------------------------------------|-------------------------------------------|
| `image.name`                | The image name       to pull from  | `purestorage/k8s`                 |
| `image.tag`                 | The image tag to pull              | `2.0.0`                                  |
| `image.pullPolicy`          | Image pull policy                  | `IfNotPresent`                            |
| `app.debug`                 | Enable/disable debug mode for app  | `false`                                  |
| `storageclass.isPureDefault`| Set `pure` storageclass to the default | `false`       |
| `clusterrolebinding.serviceAccount.name`| Name of K8s service account for app | `default`                    |
| `flasharray.sanType`        | Block volume access protocol, either ISCSI or FC | `ISCSI`                      |
| `namespace.pure`            | Namespace for the backend storage  | `k8s`                                     |
| `orchestrator.name`         | Orchestrator type, such as openshift, k8s | `k8s`                              |
| `orchestrator.k8s.flexBaseDir` | Base path of directory to install flex plugin, works with orchestrator.name=k8s and image.tag < 2.0. Sub-dir of "volume/exec/pure~flex" will be automatically created under it | `/usr/libexec/kubernetes/kubelet-plugins` |
| `orchestrator.k8s.flexPath` | Full path of directory to install flex plugin, works with orchestrator.name=k8s and image.tag >= 2.0 | `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/pure~flex` |
| `orchestrator.openshift.flexBaseDir` | Base path of directory to install flex plugin, works with orchestrator.name=openshift and image.tag < 2.0. Sub-dir of "volume/exec/pure~flex" will be automatically created under it | `/etc/origin/node/kubelet-plugins` |
| `orchestrator.openshift.flexPath` | Full path of directory to install flex plugin, works with orchestrator.name=k8s and image.tag >= 2.0 | `/etc/origin/node/kubelet-plugins/volume/exec/pure~flex` |
| *`arrays`                    | Array list of all the backend FlashArrays and FlashBlades | must be set by user, see an example below                |

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

Customize your values.yaml including arrays info (replacement for pure.json), and then install with your values.yaml. Better to set a release name such as "pure-storage-driver"

Dry run the installation, and make sure your values.yaml working correctly
```
helm install --name pure-storage-driver pure/pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml --dry-run --debug
```

Run the Install
```
helm install --name pure-storage-driver pure/pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml
```

The value in your values.yaml will overwrite the one in pure-k8s-plugin/values.yaml, but any specified with the `--set`
option will take precedence.
```
helm install --name pure-storage-driver pure/pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml --set flasharray=fc,namespace.pure=k8s_xxx,orchestrator.name=openshift
```

## How to update `arrays` info

Update your values.yaml with the correct arrays info, and then upgrade the helm as below

**Note**: Ensure that the values for `--set` options match when run with the original install step. It is highly recommended
to use the values.yaml and not specify options with `--set` to make this easier.
```
helm upgrade pure-storage-driver pure/pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml --set ...
```

# Upgrading
## How to upgrade the driver version

It's not recommended to upgrade by setting the `image.tag` in the image section of values.yaml, use the version of
the helm repository with the tag version required. This will ensure the supporting changes are present in the templates.
```
helm upgrade pure-storage-driver pure/pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml --version <target version>
```

## How to upgrade from the legacy installation to helm version

This upgrade will not impact the in-use volumes/filesystems from data path perspective. However, it will affect the in-fly volume/filesystem management operations. So, it is recommended to stop all the volume/filesystem management operations before doing this upgrade. Otherwise, these operations may need to be retried after the upgrade.

1. Uninstall the legacy installation by following [the instructions](https://hub.docker.com/r/purestorage/k8s/)
2. Reinstall via helm
    a. Convert pure.json into arrays info in your values.yaml, (online tool: https://www.json2yaml.com/)
3. Ensure either `orchestrator.k8s.flexPath` or `orchestrator.openshift.flexPath` match up exactly with kubelet's `volume-plugin-dir` parameter. 
    a. How to find the full path of the directory for pure flex plugin (i.e. `volume-plugin-dir`) 
    ```
    # ssh to a node which has pure flex plugin installed, and check the default value of "volume-plugin-dir" from "kubelet --help"
    # and then find the full path of the directory as below:

    # for k8s
    root@k8s-test-k8s-0:~# find /usr/libexec/kubernetes/kubelet-plugins/ -name "flex" | xargs dirname
    /usr/libexec/kubernetes/kubelet-plugins/volume/exec/pure~flex
    
    # for openshift
    root@k8s-test-openshift-0:~# find /etc/origin/node/kubelet-plugins/ -name "flex" | xargs dirname
    /etc/origin/node/kubelet-plugins/volume/exec/pure~flex
    ```

# Containerized Kubelet

If Kubernetes is deployed using containerized kubelet services then there
may be steps required to ensure it can use the FlexVolume plugin. In general
there are a few requirements that must be met for the plugin to work.

## Requirements
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



# Platform Specific Considerations

Some Kubernetes environments will require special configuration, especially
on restrictive host operating systems where parts of it are mounted read-only.

### CentOS/RHEL Atomic
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
path to use is something like `/etc/origin/node/kubelet-plugins` or similar
as the node config path is passed through to the container.
