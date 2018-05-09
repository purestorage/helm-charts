# pure-k8s-plugin

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

Create your own values.yaml from pure-k8s-plugin/values.yaml, and keep it
```
cp pure-k8s-plugin/values.yaml <your_own_dir>/values.yaml
```



Customize your values.yaml including arrays info (replacement for pure.json)

`Question`: Is it okay to replace pure.json? or still want to keep it? any bad impact for customer experience?

```yaml
# comment out image section as you don't need to change it 
#image:
#  name: purestorage/k8s
#  tag: 1.2.4
#  pullPolicy: IfNotPresent

# support ISCSI or FC
# could be set by passing a parameter
flasharray:
  sanType: ISCSI

# could be set by passing parameters
namespaces:
  k8s: default
  nsm: k8s

# support k8s or openshift
# could be set by passing a parameter
orchestrator:
  name: k8s

# edit arrays (pure.json)
# better to edit here
arrays:
  FlashArrays:
    - MgmtEndPoint: "1.2.3.4"
      APIToken: "c526a4c6-18b0-a8c9-1afa-3499293574bb"
  FlashBlades:
    - MgmtEndPoint: "1.2.3.5"
      APIToken: "T-d4925090-c9bf-4033-8537-d24ee5669135"
      NfsEndPoint: "1.2.3.6"
```

Install with your values.yaml. Better to set a release name such as "pure-storage-driver"
```
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

`Question`: Any non-disruptive upgrade solution?
```
1. Uninstall the legacy installation
2. Install the new version by helm
    a. convert pure.json into arrays info in your values.yaml, (online tool: https://www.json2yaml.com/)
```
