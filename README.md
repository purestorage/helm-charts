# PureStorage Helm Charts

# Installation

## Adding the `pure` repo

```bash
helm repo add pure https://purestorage.github.io/helm-charts
helm repo update
```

## Helm Setup
Please ensure you have a correct service account with cluster-admin role in K8s/Openshift for Helm. 

1. Install Helm client and tiller under a namespace(i.e. project in openshift)
```
export TILLER_NAMESPACE=tiller
# If helm is not installed, you can install as:
# For Linux
curl -s https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz | tar xz
cd linux-amd6a
# For OSX
curl -s https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-darwin-amd64.tar.gz | tar xz
$ cd darwin-amd64
# For Windows
Download and extract https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-windows-amd64.zip. Open a command prompt in the newly created windows-amd64 folder.

# Check for helm version:
./helm version

# Initialize the helm client and tiller, and configure the correct role for it
# For K8s:
./helm init
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=${TILLER_NAMESPACE}:default

# For Openshift:
./helm init --client-only
oc process -f https://github.com/openshift/origin/raw/master/examples/helm/tiller-template.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=v2.9.1 | oc create -f -
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
