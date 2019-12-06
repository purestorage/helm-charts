# Tests

## Pre-requisites

To run the tests, the following tools should be installed firstly:
* Minikube
https://kubernetes.io/docs/tasks/tools/install-minikube/
* Kubectl
https://kubernetes.io/docs/tasks/tools/install-kubectl/
* Helm
https://docs.helm.sh/using_helm/#installing-helm

## Upgrade test
`test-upgrade.sh` is to test the pure-k8s-plugin helm chart upgrade from any GA version to the current developing code.

* Setup Env variables for a test, (optional)
There are some test environment variables:
    * MINIKUBE_VM_DRIVER        | `virtualbox` (default)
    * TEST_CHARTS_REPO_URL      | `https://purestorage.github.io/helm-charts` (default)
    * TEST_CHART_GA_VERSION     | `latest` (default)

You can setup a different value for any one of them
```bash
export MINIKUBE_VM_DRIVER=none
export TEST_CHARTS_REPO_URL=https://purestorage.github.io/helm-charts
export TEST_CHART_GA_VERSION=latest
```

* Run a test:
```bash
./tests/pure-k8s-plugin/test_upgrade.sh
```
