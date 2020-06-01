FROM quay.io/operator-framework/helm-operator:v0.13.0
MAINTAINER Pure Storage, Inc.
LABEL name="pure-csi" vendor="Pure Storage" version="5.2.0" release="1.0" summary="Pure Storage CSI Operator" description="Pure Service Orchestrator CSI Operator"
COPY helm-charts/ ${HOME}/helm-charts/
COPY watches.yaml ${HOME}/watches.yaml
COPY licenses /licenses
