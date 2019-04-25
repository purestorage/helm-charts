#!/usr/bin/env bash
IMAGE=quay.io/purestorage/pso-operator:v0.0.1
NAMESPACE=pso-operator
KUBECTL=oc

usage()
{
    echo "Usage : $0 --image=<imagename> --namespace=<namespace> --orchestrator=<orchestrator> -f <values.yaml>"
    exit
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

while (("$#")); do
case "$1" in
  --image=*)
  IMAGE="${1#*=}"
  shift
  ;;
  --namespace=*)
  NAMESPACE="${1#*=}"
  shift
  ;;
  --orchestrator=*)
  ORCHESTRATOR="${1#*=}"
  if [[ "${ORCHESTRATOR}" == "k8s" || "${ORCHESTRATOR}" == "K8s" ]]; then
      KUBECTL=kubectl
  elif [[ "${ORCHESTRATOR}" == "openshift" ]]; then
      KUBECTL=oc
  else
      echo "orchestrator can only be 'k8s' or 'openshift'"
      usage
      exit
  fi
  shift
  ;;
  -f)
  if [ "$#" -lt 2 ]; then
    usage
    exit
  fi
  VALUESFILE="$2"
  shift
  shift
  ;;
  -h|--help|*)
  usage
  exit
  ;;
  esac
done

if [[ -z ${VALUESFILE} || ! -f ${VALUESFILE} ]]; then
    usage
    echo "File ${VALUESFILE} for values.yaml does not exist"
    exit 1
fi

KUBECTL_NS="${KUBECTL} apply -n ${NAMESPACE} -f"

# 1. Create the namespace
if [[ "${KUBECTL}" == "kubectl" ]]; then
    $KUBECTL create namespace ${NAMESPACE}
else
    $KUBECTL adm new-project ${NAMESPACE} 
    
    # Since this plugin needs to mount external volumes to containers, create a SCC to allow the flex-daemon pod to
    # use the hostPath volume plugin
echo '
kind: SecurityContextConstraints
apiVersion: v1
metadata:
  name: hostpath
allowPrivilegedContainer: true
allowHostDirVolumePlugin: true
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
' | $KUBECTL create -f -

    # Grant this SCC to the service account creating the flex-daemonset
    # extract the clusterrolebinding.serviceAccount.name from the values.yaml file if it exists.
    SVC_ACCNT=$(awk '/clusterrolebinding:/,0' ${VALUESFILE} | grep 'name:' | sed  ' s/#.*$//; s/^.*://; s/ *$//; /^$/d;' | head -1)
    if [[ -z ${SVC_ACCNT} ]]; then
        SVC_ACCNT=pure
    fi
    $KUBECTL adm policy add-scc-to-user hostpath -n ${NAMESPACE} -z ${SVC_ACCNT} 
fi

# 2. Create CRD and wait until TIMEOUT seconds for the CRD to be established.
counter=0
TIMEOUT=10
echo "
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: psoplugins.purestorage.com
spec:
  group: purestorage.com
  names:
    kind: PSOPlugin
    listKind: PSOPluginList
    plural: psoplugins
    singular: psoplugin
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
  subresources:
    status: {} " | ${KUBECTL} apply -f -

while true; do
  result=$(${KUBECTL} get crd/psoplugins.purestorage.com -o jsonpath='{.status.conditions[?(.type == "Established")].status}{"\n"}' | grep -i true)
  if [ $? -eq 0 ]; then
     break
  fi
  counter=$(($counter+1))
  if [ $counter -gt $TIMEOUT ]; then
     break
  fi
  sleep 1
done

if [ $counter -gt $TIMEOUT ]; then
   echo "Timed out waiting for CRD"
   exit 1
fi


# 3. Create RBAC for the PSO-Operator
echo '
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: pso-operator
rules:
  - apiGroups:
    - purestorage.com
    resources:
    - "*"
    verbs:
    - "*"
  - apiGroups:
    - ""
    resources:
    - namespaces
    verbs:
    - get
  - apiGroups:
    - storage.k8s.io
    resources:
    - storageclasses
    verbs:
    - "create"
    - "delete"
# PSO operator needs to create/delete a ClusterRoleBinding with the ClusterRole system:persistent-volume-provisioner for provisioning PVs
  - apiGroups:
    - rbac.authorization.k8s.io
    resources:
    - clusterrolebindings
    verbs:
    - "create"
    - "delete"
  - apiGroups:
    - rbac.authorization.k8s.io
    resources:
    - clusterrolebindings
    resourceNames:
    - "pure-provisioner-rights"
    verbs:
    - "get"
# On Openshift ClusterRoleBindings belong to a different apiGroup.
# PSO operator needs to create/delete a ClusterRoleBinding with the ClusterRole system:persistent-volume-provisioner for provisioning PVs
  - apiGroups:
    - authorization.openshift.io
    resources:
    - clusterrolebindings
    verbs:
    - "create"
    - "delete"
# PSO creates the ClusterRoleBinding "pure-provisioner-rights" and should be able to get this by resource name
  - apiGroups:
    - authorization.openshift.io
    resources:
    - clusterrolebindings
    resourceNames:
    - "pure-provisioner-rights"
    verbs:
    - "get"
---
# This ClusterRoleBinding is needed to create "pure-provisioner-rights" ClusterRoleBinding with ClusterRole system:persistent-volume-provisioner
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: pso-operator-volume-provisioner
subjects:
- kind: ServiceAccount
  name: default
  namespace: REPLACE_NAMESPACE
roleRef:
  kind: ClusterRole
  name: system:persistent-volume-provisioner
  apiGroup: rbac.authorization.k8s.io

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: pso-operator-role
subjects:
- kind: ServiceAccount
  name: default
  namespace: REPLACE_NAMESPACE
roleRef:
  kind: ClusterRole
  name: pso-operator
  apiGroup: rbac.authorization.k8s.io

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: pso-operator
rules:
  - apiGroups:
    - ""
    resources:
    - pods
    - services
    - endpoints
    - configmaps
    - secrets
    - serviceaccounts
    verbs:
    - "*"
  - apiGroups:
    - ""
    resources:
    - namespaces
    verbs:
    - get
  - apiGroups:
    - apps
    resources:
    - deployments
    - daemonsets
    verbs:
    - "*"
  - apiGroups:
    - extensions
    resources:
    - daemonsets
    verbs:
    - "*"

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: default-account-pso-operator
subjects:
- kind: ServiceAccount
  name: default
roleRef:
  kind: Role
  name: pso-operator
  apiGroup: rbac.authorization.k8s.io
' | sed "s|REPLACE_NAMESPACE|${NAMESPACE}|" | ${KUBECTL_NS} -

# 4. Create a PSO-Operator Deployment
echo '
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pso-operator
spec:
  replicas: 1
  selector:
    matchLabels:
      name: pso-operator
  template:
    metadata:
      labels:
        name: pso-operator
    spec:
      serviceAccountName: default
      containers:
        - name: pso-operator
          # Replace this with the built image name
          image: REPLACE_IMAGE
          ports:
          - containerPort: 60000
            name: metrics
          imagePullPolicy: Always
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "pso-operator"
' | sed "s|REPLACE_IMAGE|${IMAGE}|" | ${KUBECTL_NS} -

# 5. Use the values.yaml file to create a customized PSO operator instance
( echo '
apiVersion: purestorage.com/v1
kind: PSOPlugin
metadata:
  name: psoplugin-operator
  namespace: REPLACE_NAMESPACE
spec:
  # Add fields here' | sed "s|REPLACE_NAMESPACE|${NAMESPACE}|"; sed 's/.*/  &/' ${VALUESFILE}) | ${KUBECTL_NS} -

