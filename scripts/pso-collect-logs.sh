#!/usr/bin/env bash
FULL_MODE="false"
while [ -n "$1" ]; do # while loop starts
  case "$1" in

  --full)
    echo "--full option specified"
    FULL_MODE="true";;

  --help)
    echo -e "Usage: *.bash [OPTION]"
    echo -e "If kubeconfig is not configured please run: export KUBECONFIG=[kube-config-file]\n"
    echo -e "--full: full log mode, collect pod information outside of PSO and kube-system namespace, please make sure there is no sensitive information."
    exit;;

  *)
    echo "Option $1 not recognized, use --help for more information."
    exit;;

  esac
  shift
done

if [ "$FULL_MODE" == "false" ]; then
    tput setaf 2;
    echo -e "Will not collect user application info, if there is PVC mount issue, please run with --full option to collect info for all pods in all namespaces, make sure there is no sensitive info."
    tput sgr0
fi

KUBECTL=kubectl

if [ -n "$(which oc)" ]; then
  echo "oc exists, use oc instead of kubectl"
  KUBECTL=oc
fi

LOG_DIR=./pso-logs
PSO_NS=$($KUBECTL get pod -o wide --all-namespaces | grep pure-provisioner- | awk '{print $1}')

tput setaf 2;
echo -e "PSO namespace is $PSO_NS, overwritting log dir $LOG_DIR\n"
tput sgr0

PODS=$($KUBECTL get pod -n $PSO_NS | awk '{print $1}' | grep -e pure-)

if [ -d "$LOG_DIR" ]
then
    rm $LOG_DIR -r
fi
mkdir $LOG_DIR

if [[ $KUBECTL == "oc" ]]; then
  echo "collect scc info"
  # Get log for scc which only exists in openshift cluster, in case oc exists but the cluster is k8s cluster
  # we will get "resource type does not exist", which is ok.
  oc get scc -o wide > $LOG_DIR/scc.log 2>/dev/null
  echo -e "\n" >> $LOG_DIR/scc.log
  oc describe scc >> $LOG_DIR/scc.log 2>/dev/null
fi

for pod in $PODS
do
  echo "collect logs for pod $pod"

  # For flex driver
  if [[ $pod == *"pure-flex-"* ]]; then
    $KUBECTL logs $pod -c pure-flex -n $PSO_NS > $LOG_DIR/$pod.log
  fi

  if [[ $pod == *"pure-provisioner-"* ]]; then
    $KUBECTL logs $pod -c pure-provisioner -n $PSO_NS > $LOG_DIR/$pod.log
  fi
  # For csi driver
  if [[ $pod == *"pure-csi-"* ]] || [[ $pod == *"pure-provisioner-0"* ]] ; then
    $KUBECTL logs $pod -c pure-csi-container -n $PSO_NS > $LOG_DIR/$pod.log
  fi

done

if [ "$FULL_MODE" == "true" ]; then
  echo "collect info for all pods in all namespaces"
  $KUBECTL get pod --all-namespaces -o wide > $LOG_DIR/all-pods.log
  echo -e "\n" >> $LOG_DIR/all-pods.log
  $KUBECTL describe pod --all-namespaces >> $LOG_DIR/all-pods.log
else
  echo "collect info for pods in PSO namespace $PSO_NS and kube-system namespace"
  $KUBECTL get pod -n $PSO_NS -o wide > $LOG_DIR/all-pods.log
  $KUBECTL get pod -n kube-system -o wide >> $LOG_DIR/all-pods.log
  echo -e "\n" >> $LOG_DIR/all-pods.log
  $KUBECTL describe pod -n $PSO_NS >> $LOG_DIR/all-pods.log
  $KUBECTL describe pod -n kube-system >> $LOG_DIR/all-pods.log
fi

echo "collect logs for all nodes"
$KUBECTL get node -o wide > $LOG_DIR/all-nodes.log

echo "collect logs for all pvcs"
$KUBECTL get pvc -o wide > $LOG_DIR/all-pvcs.log
echo -e "\n" >> $LOG_DIR/all-pvcs.log
$KUBECTL describe pvc >> $LOG_DIR/all-pvcs.log

echo "collect logs for all pvs"
$KUBECTL get pv -o wide > $LOG_DIR/all-pvs.log
echo -e "\n" >> $LOG_DIR/all-pvs.log
$KUBECTL describe pv >> $LOG_DIR/all-pvs.log

echo "collect logs for all resources in PSO namespace"
$KUBECTL get all -o wide -n $PSO_NS > $LOG_DIR/all-resource.log
echo -e "\n" >> $LOG_DIR/all-resource.log
# Supress potential error: Error from server (NotFound): the server could not find the requested resource
$KUBECTL describe all -n $PSO_NS >> $LOG_DIR/all-resource.log 2>/dev/null

COMPRESS_FILE=pso-logs-$(date "+%Y.%m.%d-%H.%M.%S").tar.gz
tput setaf 2;
echo -e "Compressing log folder $LOG_DIR into $COMPRESS_FILE"
tput sgr0
tar -czvf $COMPRESS_FILE $LOG_DIR >/dev/null


