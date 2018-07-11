#!/usr/bin/env bash

set -ex

SCRIPT_DIR=$(dirname $0)
cd ${SCRIPT_DIR}

for CHART_FILE in $(find "${SCRIPT_DIR}" -name Chart.yaml); do
    CHART_DIR=$(dirname "${CHART_FILE}")
    CHART_NAME=$(basename "${CHART_DIR}")
    helm package "${CHART_DIR}"
    mv "${SCRIPT_DIR}"/"${CHART_NAME}"*.tgz "${SCRIPT_DIR}/docs/"
done

helm repo index docs --url https://purestorage.github.io/helm-charts
echo "Updated ${SCRIPT_DIR}/docs/index.yaml"
