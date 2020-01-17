#!/usr/bin/env bash
IMAGE=quay.io/purestorage/pso-operator:v5.0.5
NAMESPACE=pure-csi-operator
KUBECTL=kubectl
ORCHESTRATOR=k8s

usage()
{
    echo "Usage : $0 --image=<imagename> --namespace=<namespace> --orchestrator=<orchestrator> -f <values.yaml>"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit
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

CRDAPIVERSION="$(${KUBECTL} explain CustomResourceDefinition | grep "VERSION:" | awk '{ print $2 }')"
CLUSTERROLEAPIVERSION="$(${KUBECTL} explain ClusterRole | grep "VERSION:" | awk '{ print $2 }')"
CLUSTERROLEBINDINGAPIVERSION="$(${KUBECTL} explain ClusterRoleBinding | grep "VERSION:" | awk '{ print $2 }')"
ROLEAPIVERSION="$(${KUBECTL} explain Role | grep "VERSION:" | awk '{ print $2 }')"
ROLEBINDINGAPIVERSION="$(${KUBECTL} explain RoleBinding | grep "VERSION:" | awk '{ print $2 }')"
DEPLOYMENTAPIVERSION="$(${KUBECTL} explain Deployment | grep "VERSION:" | awk '{ print $2 }')"

if [[ -z ${VALUESFILE} || ! -f ${VALUESFILE} ]]; then
    echo "File ${VALUESFILE} does not exist"
    usage
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
    SVC_ACCNT=$( cat ${VALUESFILE} | sed 's/#.*$//' | awk '/clusterrolebinding:/,0' | grep 'name:' | sed  ' s/^.*://; s/ *$//; /^$/d;' | head -1)
    if [[ -z ${SVC_ACCNT} ]]; then
        SVC_ACCNT=pure
    fi
    $KUBECTL adm policy add-scc-to-user hostpath -n ${NAMESPACE} -z ${SVC_ACCNT} 
fi

# 2. Create CRD and wait until TIMEOUT seconds for the CRD to be established.
counter=0
TIMEOUT=10
echo "
apiVersion: ${CRDAPIVERSION}
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
echo "
kind: ClusterRole
apiVersion: ${CLUSTERROLEAPIVERSION}
metadata:
  name: pso-operator
rules:
  - apiGroups:
    - purestorage.com
    resources:
    - \"*\"
    verbs:
    - \"*\"
  - apiGroups:
    - \"\"
    resources:
    - namespaces
    verbs:
    - get
  - apiGroups:
    - storage.k8s.io
    resources:
    - storageclasses
    verbs:
    - \"create\"
    - \"delete\"
# PSO operator needs to create/delete a ClusterRole and ClusterRoleBinding for provisioning PVs
  - apiGroups:
    - rbac.authorization.k8s.io
    resources:
    - clusterrolebindings
    - clusterroles
    verbs:
    - \"create\"
    - \"delete\"
    - \"get\"
# On Openshift ClusterRoleBindings belong to a different apiGroup.
  - apiGroups:
    - authorization.openshift.io
    resources:
    - clusterrolebindings
    - clusterroles
    verbs:
    - \"create\"
    - \"delete\"
    - \"get\"
# Need the same permissions as pure-provisioner-clusterrole to be able to create it
  - apiGroups:
    - \"\"
    resources:
    - persistentvolumes
    verbs:
    - \"create\"
    - \"delete\"
    - \"get\"
    - \"list\"
    - \"watch\"
    - \"update\"
  - apiGroups:
    - \"\"
    resources:
    - persistentvolumeclaims
    verbs:
    - \"get\"
    - \"list\"
    - \"update\"
    - \"watch\"
  - apiGroups:
    - storage.k8s.io
    resources:
    - storageclasses
    verbs:
    - \"get\"
    - \"list\"
    - \"watch\"
# Need the same permissions as external-provisioner-runner clusterrole to be able to create it
  - apiGroups:
    - \"\"
    resources:
    - \"events\"
    verbs:
    - \"create\"
    - \"patch\"
    - \"update\"
    - \"watch\"
    - \"list\"
    - \"get\"
  - apiGroups:
    - snapshot.storage.k8s.io
    resources:
    - \"volumesnapshots\"
    verbs:
    - \"get\"
    - \"list\"
    - \"watch\"
    - \"update\"
  - apiGroups:
    - snapshot.storage.k8s.io
    resources:
    - \"volumesnapshots/status\"
    verbs:
    - \"update\"
  - apiGroups:
    - snapshot.storage.k8s.io
    resources:
    - \"volumesnapshotcontents\"
    verbs:
    - \"create\"
    - \"get\"
    - \"list\"
    - \"watch\"
    - \"update\"
    - \"delete\"
  - apiGroups:
    - snapshot.storage.k8s.io
    resources:
    - \"volumesnapshotclasses\"
    verbs:
    - \"get\"
    - \"list\"
    - \"watch\"
  - apiGroups: 
    - storage.k8s.io
    resources: 
    - \"csinodes\"
    verbs: 
    - \"get\"
    - \"list\"
    - \"watch\"
  - apiGroups: 
    - \"\"
    resources:
    - \"nodes\"
    verbs:
    - \"get\"
    - \"list\"
    - \"watch\"
# Need the same permissions as driver-registrat-runner clusterrole to be able to create it. Only for K8s 1.13
  - apiGroups: 
    - \"apiextensions.k8s.io\"
    resources: 
    - \"customresourcedefinitions\"
    verbs: 
    - \"*\"
  - apiGroups: 
    - \"csi.storage.k8s.io\"
    resources:
    - \"csidrivers\"
    verbs: 
    - \"*\"
  - apiGroups: 
    - \"storage.k8s.io\"
    resources:
    - \"csidrivers\"
    verbs: 
    - \"*\"

---
kind: ClusterRoleBinding
apiVersion: ${CLUSTERROLEBINDINGAPIVERSION}
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
apiVersion: ${ROLEAPIVERSION}
metadata:
  name: pso-operator
rules:
  - apiGroups:
    - \"\"
    resources:
    - pods
    - services
    - endpoints
    - configmaps
    - secrets
    - serviceaccounts
    verbs:
    - \"*\"
  - apiGroups:
    - \"\"
    resources:
    - namespaces
    verbs:
    - get
  - apiGroups:
    - apps
    resources:
    - deployments
    - daemonsets
    - statefulsets
    verbs:
    - \"*\"
  - apiGroups:
    - extensions
    resources:
    - daemonsets
    verbs:
    - \"*\"
  - apiGroups:
    - rbac.authorization.k8s.io
    resources:
    - roles
    - rolebindings
    verbs:
    - \"*\"
  - apiGroups:
    - authorization.openshift.io
    resources:
    - roles
    - rolebindings
    verbs:
    - \"*\"

---

kind: RoleBinding
apiVersion: ${ROLEBINDINGAPIVERSION}
metadata:
  name: default-account-pso-operator
subjects:
- kind: ServiceAccount
  name: default
roleRef:
  kind: Role
  name: pso-operator
  apiGroup: rbac.authorization.k8s.io
" | sed "s|REPLACE_NAMESPACE|${NAMESPACE}|" | ${KUBECTL_NS} -

# 4. Create a PSO-Operator Deployment
echo "
apiVersion: ${DEPLOYMENTAPIVERSION}
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
              value: \"pso-operator\"
" | sed "s|REPLACE_IMAGE|${IMAGE}|" | ${KUBECTL_NS} -

# 5. Use the values.yaml file to create a customized PSO operator instance
( echo '
apiVersion: purestorage.com/v1
kind: PSOPlugin
metadata:
  name: psoplugin-operator
  namespace: REPLACE_NAMESPACE
spec:
  # Add fields here' | sed "s|REPLACE_NAMESPACE|${NAMESPACE}|"; sed 's/.*/  &/' ${VALUESFILE}) | ${KUBECTL_NS} -

counter=0
TIMEOUT=30

while true; do
   result=$(${KUBECTL} get crd/volumesnapshotclasses.snapshot.storage.k8s.io -o jsonpath='{.status.conditions[?(.type == "Established")].status}{"\n"}' --ignore-not-found | grep -i true)
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
   echo "VolumeSnapshotClasss CRD not found!"
else
    $KUBECTL apply -f ../pure-csi/snapshotclass.yaml
fi
