#!/usr/bin/env bash
# Script to Upgrade PSO FlexDriver

usage()
{
    echo "Usage : $0 --version=<versionnumber> -f <values.yaml>"
    exit
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

while (("$#")); do
  case "$1" in
    --version=*)
      VERSION="${1#*=}"
      NEW_VERSION=`echo $VERSION | awk '{print tolower($1)}' -`
      V_CHAR=`echo $NEW_VERSION | awk '{print substr($1,1,1)}' -`
      if [ $V_CHAR != "v" ]; then
        NEW_VERSION=`echo $NEW_VERSION | awk '$0="v"$0' -`
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
  echo "Error: Failed to identify namespace for PSO. Please ensure it is installed and running properly"
  exit 1
fi

# Discover the image we are currently using
# For dark-sites we retain the registry location for the upgrade

IMAGE_LOC=`$KUBECTL describe deployment pso-operator -n $NAMESPACE | grep Image | sed 's/ //g' | awk 'BEGIN{FS=":"};{print $2}' -`
IMAGE_VER=`$KUBECTL describe deployment pso-operator -n $NAMESPACE | grep Image | sed 's/ //g' | awk 'BEGIN{FS=":"};{print $3}' -`

if [ -z $IMAGE_VER ]; then
  echo "Error: Failed to identify image being used"
  exit 1
fi

if [ $IMAGE_VER == $NEW_VERSION ]; then
  echo "Error: New version already installed"
  exit 1
fi

# Quietly Upggrade PSO

COLON=":"

./install.sh --image=$IMAGE_LOC$COLON$NEW_VERSION --namespace=$NAMESPACE --orchestrator=$ORCHESTRATOR -f $VALUESFILE > /dev/null 2>&1

$KUBECTL rollout status deployment pure-provisioner -n $NAMESPACE >/dev/null 2>&1
