# PureStorage Helm Charts

# Installation

## Adding the `pure` repo

```bash
helm repo add pure https://purestorage.github.io/helm-charts
helm repo update
```

## Helm Setup
Please ensure you have a correct service account with cluster-admin role in K8s/Openshift for Helm. 

Install the helm by following the official documents:
1. For Kubernetes
https://docs.helm.sh/using_helm#install-helm

2. For Openshift
https://blog.openshift.com/getting-started-helm-openshift/

# In order to enable helm tiller to install any type of services across the entire cluster, it's required to grant helm tiller with cluster admin role.
# After helm installation, configure the cluster admin role for the service account of the helm tiller. You need to figure out the correct service account.
# For K8s, for exmaple of a service account {TILLER_NAMESPACE}:default
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=${TILLER_NAMESPACE}:default

# For Openshift:
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:${TILLER_NAMESPACE}:tiller
```

For more details, please see https://docs.helm.sh/using_helm/

# Updating Charts
We serve charts using a github page with its root at [./docs](./docs) when the helm source is updated
we need to do something like:

```bash
helm package ./$CHART_NAME
cp $CHART_NAME.tgz ./docs
helm repo index docs --url https://purestorage.github.io/helm-charts
```

Luckily there is a helper script to make this easy:

```bash
./update.sh
```

You can then commit the changes and have them become available once merged.
