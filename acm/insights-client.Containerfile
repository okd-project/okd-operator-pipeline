FROM registry-proxy.engineering.redhat.com/rh-osbs/rhacm2-dockerfile-drifter:latest AS drifter
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/insights-client/app

COPY Dockerfile.cached Dockerfile.cached
RUN /dockerfile-drifter.sh Dockerfile Dockerfile.cached

#@follow_tag(registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:rhel_9_1.23)
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23.6-202503041452.g6c23478.el9 AS builder

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=insights-client
ENV COMPONENT_VERSION=2.13.3
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR
WORKDIR $REMOTE_SOURCES_DIR/insights-client/app

RUN mkdir output
RUN source $REMOTE_SOURCES_DIR/insights-client/cachito.env && go build -tags strictfipsruntime -trimpath -o main main.go

# Dummy copy command to force execution of drifter
COPY --from=drifter /dockerfile-drifter.sh /tmp/drifter.sh


#@follow_tag(registry.redhat.io/ubi9-minimal:latest)
FROM registry.redhat.io/ubi9-minimal:9.6-1747218906

RUN microdnf install ca-certificates vi --nodocs -y &&\
    mkdir /licenses &&\
    microdnf clean all

ENV VCS_REF="bbcd364562002cbaacf4c514dfc8c514adc4922c" \
    USER_UID=1001

COPY --from=builder $REMOTE_SOURCES_DIR/insights-client/app/main /bin/main


EXPOSE 3030
USER ${USER_UID}
ENTRYPOINT ["/bin/main"]


LABEL com.redhat.component="insights-client-container" \
      name="rhacm2/insights-client-rhel9" \
      version="v2.13.3" \
      upstream-ref="334a27b3590a83db535d869a27214ee0cdb8322d" \
      upstream-url="git@github.com:stolostron/insights-client.git" \
      summary="insights-client" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="insights-client" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="insights-client"

# 20221024
