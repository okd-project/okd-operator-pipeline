FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default .git/modules/ingress-node-firewall/ .git/modules/ingress-node-firewall/
COPY --chown=default ingress-node-firewall/operator ingress-node-firewall/operator

WORKDIR /opt/app-root/src/ingress-node-firewall/operator
RUN ./hack/build-daemon.sh

FROM quay.io/centos/centos:stream9

COPY --from=builder /opt/app-root/src/ingress-node-firewall/operator/bin/daemon /usr/bin/
COPY --from=builder /opt/app-root/src/ingress-node-firewall/operator/bin/syslog /usr/bin/

CMD ["/usr/bin/daemon"]

