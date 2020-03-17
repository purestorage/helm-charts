#!/usr/bin/env bash

set -xe
PSO_OPERATOR_IMG_TAG=${PSO_OPERATOR_IMG_TAG:-pso-operator:latest}
IMG_DIR=$(dirname $0)
HELM_DIR=${IMG_DIR}/..
if [ -d "${IMG_DIR}/helm-charts" ]; then rm -rf ${IMG_DIR}/helm-charts; fi
mkdir -p ${IMG_DIR}/helm-charts
cp -r ${HELM_DIR}/pure-csi ${IMG_DIR}/helm-charts

docker build -t ${PSO_OPERATOR_IMG_TAG} ${IMG_DIR}
