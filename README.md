# PureStorage Helm Charts

# Installation

Please ensure you have a correct service account in K8s for Helm. If not, create it as below
```
# # Create a service account for Helm and grant the cluster admin role.
# It is assumed that helm should be installed with this service account (tiller).

kubectl apply -f helm-service-account.yaml
```