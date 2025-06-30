###########################################################################
# Istio Must-gather image                                                 #
###########################################################################

FROM quay.io/openshift/origin-must-gather:4.18

ARG MUST_GATHER_GIT_TAG
ARG MUST_GATHER_GIT_SHA
ARG MUST_GATHER_GIT_URL

# Name must match the repository name
LABEL com.github.url="${MUST_GATHER_GIT_URL}"
LABEL com.github.commit="${MUST_GATHER_GIT_SHA}"
LABEL summary="OKD Service Mesh Must Gather OKD container image"
LABEL description="OKD Service Mesh Must Gather OKD container image"
LABEL version="${MUST_GATHER_GIT_TAG}"
LABEL io.k8s.display-name="OKD Service Mesh Must Gather"
LABEL io.k8s.description="OKD Service Mesh Must Gather OKD container image"

ENV container="oci"

COPY istio-must-gather/gather_istio.sh /usr/bin/gather_istio

RUN mv /usr/bin/gather /usr/bin/gather_original && \
    mv /usr/bin/gather_istio /usr/bin/gather && \
    chmod +x /usr/bin/gather

# Container image needs to contain licensing info
COPY istio-must-gather/LICENSE /licenses/LICENSE

# Ensure we do not run as root
USER 1000

ENTRYPOINT [ "/usr/bin/gather" ]
