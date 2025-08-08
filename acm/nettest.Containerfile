ARG VERSION
FROM quay.io/centos/centos:stream9-minimal

WORKDIR /app

# Upstream expects Busybox nc, we install nmap-ncat and a wrapper
RUN microdnf -y update && \
    microdnf -y install --nodocs bind-utils iputils iperf3 tcpdump nmap-ncat iproute hostname && \
    microdnf clean all && \
    rm -f /usr/bin/nc

RUN echo $VERSION >> /app/version

COPY shipyard/scripts/nettest/* /usr/bin/
COPY shipyard/scripts/nettest/* /app/

CMD ["/bin/bash","-l"]

LABEL summary="nettest" \
      io.k8s.display-name="nettest" \
      io.k8s.description="nettest" \
      maintainer="maintainers@okd.io" \
      description="nettest"
