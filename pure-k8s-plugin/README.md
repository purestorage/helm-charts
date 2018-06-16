# pure-k8s-plugin

## Version restrictions

Minimum Helm version required is 2.9.1
Minimum version of K8S FlexVol driver required is 2.0

## How to install

Download the helm chart (will be replaced by helm repo solution below)
```
git clone https://github.com/purestorage/helm-charts.git
cd helm-charts
```

`TODO`: Install charts from helm repo
```
# TODO:
helm repo add pure https://github.com/purestorage/helm-charts
helm repo update
helm search pure-k8s-plugin
```

Create your own values.yaml and install the helm chart with it, and keep it

### Configuration

The following table lists the configurable parameters and their default values.

|             Parameter       |            Description             |                    Default                |
|-----------------------------|------------------------------------|-------------------------------------------|
| `image.name`                | The image name       to pull from  | `purestorage/k8s`                 |
| `image.tag`                 | The image tag to pull              | `latest`                                  |
| `image.pullPolicy`          | Image pull policy                  | `IfNotPresent`                            |
| `app.debug`                 | Enable/disable debug mode for app  | `false`                                  |
| `storageclass.isPureDefault`| Set pure storageclass to the default | `false`       |
| `clusterrolebinding.serviceAccount.name`| Name of K8s service account for app | `default`                    |
| `flasharray.sanType`        | Block volume access protocol, either ISCSI or FC | `ISCSI`                      |
| `namespaces.k8s`            | Kubernetes namespace for running app | `default`                    |
| `namespaces.nsm`            | Namespace of the backend storages  | `k8s`                                     |
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
```
# Dry run the installation firstly, and make sure yourvalues.yaml working correctly
helm install --name pure-storage-driver pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml --dry-run --debug

# Install
helm install --name pure-storage-driver pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml
```

Install with your values.yaml and overwrite some values by "--set"
```
# the value in your values.yaml will overwrite the one in pure-k8s-plugin/values.yaml,
# the value set by "--set" will overwrite the one in both yourvalues.yaml and pure-k8s-plugin/values.yaml

helm install --name pure-storage-driver pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml --set flasharray=fc,namespaces.nsm=k8s_xxx,orchestrator.name=openshift
```

## How to update arrays info

Update your values.yaml with the correct arrays info, and then upgrade the helm as below
```
# need to set the same values with "--set" which is same as in your install command,
# it's better to save all your customized values into yourvalues.yaml. So that, no "--set" is needed

cd helm-charts
helm upgrade pure-storage-driver pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml --set ...
```

## How to upgrade the driver version

It's not recommended to upgrade by setting the values in the image section of values.yaml
```
cd helm-charts
git pull
helm upgrade pure-storage-driver pure-k8s-plugin -f <your_own_dir>/yourvalues.yaml
```

# How to upgrade from the legacy installation to helm version

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
