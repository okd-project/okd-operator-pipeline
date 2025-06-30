###########################################################################
# OSSMC plugin build                                                      #
###########################################################################

FROM registry.access.redhat.com/ubi9/nodejs-20 AS uibuilder

# Environment variables
ENV KIALI_ENV=production

# Run as root to install yarn
USER 0

WORKDIR /src/yarn

# Install yarn
RUN npm install -g yarn && \
    \
    # Show node and yarn versions
    node --version && \
    yarn --version

WORKDIR /src/ossmc

# Copy the OSSMC plugin source code
COPY kiali-console-plugin/plugin .

# Build the OSSMC plugin
RUN yarn install --frozen-lockfile --ignore-scripts && \
    yarn build && \
    \
    # Move the plugin to a temporal folder
    mv ./dist /tmp/dist && \
    rm -rf /src

###########################################################################
# OSSMC log script update                                                 #
###########################################################################

FROM registry.access.redhat.com/ubi9/nginx-124 as builder

ARG OPENSHIFT_SERVICEMESH_PLUGIN_GIT_TAG \
    OPENSHIFT_SERVICEMESH_PLUGIN_GIT_SHA

# Run as root to modify the file
USER 0

# Any file has to be modified in a previous builder stage to avoid the HasModifiedFiles error
# https://docs.redhat.com/en/documentation/red_hat_software_certification/2024/html-single/red_hat_openshift_software_certification_policy_guide/index#con-image-content-requirements_openshift-sw-cert-policy-container-images
RUN printf "\necho 'OpenShift Service Mesh Console: Version=[${OPENSHIFT_SERVICEMESH_PLUGIN_GIT_TAG}], Commit=[${OPENSHIFT_SERVICEMESH_PLUGIN_GIT_SHA}]' >> /proc/1/fd/1" >> ${NGINX_CONTAINER_SCRIPTS_PATH}/common.sh

###########################################################################
# OSSMC plugin mage                                                       #
###########################################################################

FROM registry.access.redhat.com/ubi9/nginx-124

ARG OPENSHIFT_SERVICEMESH_PLUGIN_GIT_TAG \
    OPENSHIFT_SERVICEMESH_PLUGIN_GIT_SHA \
    OPENSHIFT_SERVICEMESH_PLUGIN_GIT_URL \
    # 1000 is widely used as non-root user
    USER_UID=1000

# Name must match the repository name
LABEL com.redhat.component="kiali-ossmc-container" \
      com.github.url="${OPENSHIFT_SERVICEMESH_PLUGIN_GIT_URL}" \
      com.github.commit="${OPENSHIFT_SERVICEMESH_PLUGIN_GIT_SHA}" \
      summary="OKD Service Mesh Console Container" \
      description="Microservices mesh observation plugin for OKD Console" \
      version="${OPENSHIFT_SERVICEMESH_PLUGIN_GIT_TAG}" \
      io.k8s.display-name="OKD Service Mesh Console" \
      io.k8s.description="Microservices mesh observation plugin for OKD Console"

ENV KIALI_OSSMC_CONTAINER_VERSION="${OPENSHIFT_SERVICEMESH_PLUGIN_GIT_TAG}"

WORKDIR /usr/libexec/s2i

# Copy the OSSMC plugin from the UI builder stage
COPY --from=uibuilder --chown=${USER_UID}:${USER_UID} /tmp/dist /usr/share/nginx/html/

# Copy the modified common.sh file from the previous builder stage
COPY --from=builder --chown=${USER_UID}:${USER_UID} ${NGINX_CONTAINER_SCRIPTS_PATH}/common.sh ${NGINX_CONTAINER_SCRIPTS_PATH}/common.sh

# Copy the OSSMC license
COPY openshift-servicemesh-plugin/LICENSE /licenses/LICENSE

EXPOSE 9443

# Ensure we do not run as root
USER ${USER_UID}

ENTRYPOINT ["/usr/libexec/s2i/run"]
