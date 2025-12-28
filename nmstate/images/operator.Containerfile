ARG OCP_SHORT

FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default . .

RUN GO111MODULE=on go build --mod=vendor -o build/_output/bin/manager ./cmd/operator

FROM registry.ci.openshift.org/origin/scos-$OCP_SHORT:base-stream9

COPY --from=builder /opt/app-root/src/build/_output/bin/manager /usr/bin/
COPY deploy/crds/nmstate.io_nodenetwork*.yaml /bindata/kubernetes-nmstate/crds/
COPY deploy/handler/namespace.yaml /bindata/kubernetes-nmstate/namespace/
COPY deploy/handler/operator.yaml /bindata/kubernetes-nmstate/handler/handler.yaml
COPY deploy/handler/service_account.yaml /bindata/kubernetes-nmstate/rbac/
COPY deploy/handler/role.yaml /bindata/kubernetes-nmstate/rbac/
COPY deploy/handler/role_binding.yaml /bindata/kubernetes-nmstate/rbac/
COPY deploy/handler/cluster_role.yaml /bindata/kubernetes-nmstate/rbac/
COPY deploy/handler/network_policy.yaml /bindata/kubernetes-nmstate/netpol/handler.yaml
COPY deploy/openshift/ui-plugin/ /bindata/kubernetes-nmstate/openshift/ui-plugin/
COPY --from=builder /opt/app-root/src/manifests /manifests
COPY --from=builder /opt/app-root/src/metadata /metadata

ENTRYPOINT ["manager"]

LABEL io.k8s.display-name="kubernetes-nmstate-operator" \
      io.k8s.description="Operator for Node network configuration through Kubernetes API" \
      io.openshift.tags="openshift,kubernetes-nmstate-operator" \
      com.redhat.delivery.appregistry=true \
      maintainer="OKD Community <maintainers@okd.io>"
