#!/usr/bin/env bash

set -xe
PSO_OPERATOR_IMAGE_TAG=${PSO_OPERATOR_IMAGE_TAG:-pso-operator:latest}
IMG_DIR=$(dirname $0)
HELM_DIR=${IMG_DIR}/..
mkdir -p ${IMG_DIR}/helm-charts
cp -r ${HELM_DIR}/pure-csi ${IMG_DIR}/helm-charts

docker build -t ${PSO_OPERATOR_IMAGE_TAG} ${IMG_DIR} 
