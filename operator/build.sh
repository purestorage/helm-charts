#!/usr/bin/env bash

set -xe
IMG_TAG=pso-operator:latest
IMG_DIR=$(dirname $0)
HELM_DIR=${IMG_DIR}/..
mkdir -p ${IMG_DIR}/helm-charts
cp -r ${HELM_DIR}/pure-k8s-plugin ${IMG_DIR}/helm-charts

docker build -t ${IMG_TAG} ${IMG_DIR} 
