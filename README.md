# PureStorage Helm Charts

# Installation

Please ensure you have a correct service account with cluster-admin role in K8s/Openshift for Helm. 

For K8s, if you hit the following error, solve it as
```
Error:
# helm list
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"

Solve it by:
# kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
```

For Openshift, you may need extra step to configure RBAC for plugin
```
Configure RBAC for helm/tiller for installing
# oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kube-system:default

Configure RBAC for plugin (assume it is installed in project of "yourproject")
# oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:yourproject:default
```

For more details, please see https://docs.helm.sh/using_helm/

# Updating Charts
We serve charts using a github page with its root at [./docs](./docs) when the helm source is updated
we need to do something like:

```bash
helm package ./$CHART_NAME>
cp $CHART_NAME.tgz ./docs
helm repo index docs --url https://purestorage.github.com/helm-charts
```

You can then commit the changes and have them become available once merged.
