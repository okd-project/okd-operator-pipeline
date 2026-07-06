FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS builder

COPY --chown=default ./autoscaler/vertical-pod-autoscaler .
RUN go build ./pkg/admission-controller
RUN go build ./pkg/updater
RUN go build ./pkg/recommender

FROM quay.io/centos/centos:stream9

COPY --from=builder \
    /opt/app-root/src/admission-controller \
    /opt/app-root/src/updater \
    /opt/app-root/src/recommender \
    /usr/bin/
LABEL summary="Vertical Pod Autoscaler for OKD and Kubernetes"
