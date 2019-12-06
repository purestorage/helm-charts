#!/usr/bin/env bash
# Script to Update PSO Arrays configurations after modification of values.yaml

usage()
{
    echo "Usage : $0 -f <values.yaml>"
    exit
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

while (("$#")); do
case "$1" in
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

# Find out if this is OpenShift

OC=/usr/bin/oc

if [ -f "$OC" ]; then
  KUBECTL=oc
  ORCHESTRATOR=openshift
else
  KUBECTL=kubectl
  ORCHESTRATOR=k8s
fi

# Discover which namespace we have installed PSO in

NAMESPACE=`$KUBECTL get deployment --all-namespaces | grep pure-provisioner | awk '{print $1}' -`
if [ -z $NAMESPACE ]; then
  echo "Error: Please confirm Namespace for PSO"
  exit 1
fi

# Discover the image we are currently using

IMAGE=`$KUBECTL describe deployment pso-operator -n $NAMESPACE | grep Image | awk '{print $2}' -`
if [ -z $IMAGE ]; then
  echo "Error: Failed to identify image being used"
  exit 1
fi

# Quietly Reinstall PSO

./install.sh --image=$IMAGE --namespace=$NAMESPACE --orchestrator=$ORCHESTRATOR -f $VALUESFILE > /dev/null 2>&1

$KUBECTL rollout status deployment pure-provisioner -n $NAMESPACE >/dev/null 2>&1 

