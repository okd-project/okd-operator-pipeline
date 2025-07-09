FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

COPY Dockerfile.nettest.cached Dockerfile.nettest.cached
RUN /dockerfile-drifter.sh package/Dockerfile.nettest Dockerfile.nettest.cached

#----------------------------------------#


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

# Dummy copy command to force execution of drifter and then deleting the dummy copied file to clean up
COPY --from=drifter $REMOTE_SOURCE_DIR/app/Dockerfile.nettest.cached /tmp/Dockerfile.nettest.cached
RUN rm /tmp/Dockerfile.nettest.cached

WORKDIR /app

# Upstream expects Busybox nc, we install nmap-ncat and a wrapper
RUN microdnf -y update && \
    microdnf -y install --nodocs bind-utils iputils iperf3 tcpdump nmap-ncat iproute hostname && \
    microdnf clean all && \
    rm -f /usr/bin/nc

RUN echo v0.20.1 >> /app/version

COPY nc /usr/bin/

COPY $REMOTE_SOURCE/app/scripts/nettest/* /app/
COPY metricsproxy /app/

CMD ["/bin/bash","-l"]

LABEL com.redhat.component="nettest-container" \
      name="rhacm2/nettest-rhel9" \
      version="v0.20.1" \
      com.github.url="https://github.com/submariner-io/shipyard.git" \
      com.github.commit="71ea18a53850490c087c354a07cbbd853976ccd2" \
      summary="nettest" \
      io.openshift.expose-services="" \
      io.openshift.tags="submariner,nettest,rhel9" \
      io.openshift.wants="" \
      io.openshift.non-scalable="true" \
      io.k8s.display-name="nettest" \
      io.k8s.description="nettest" \
      maintainer="['multi-cluster-networking@redhat.com']" \
      description="nettest"
