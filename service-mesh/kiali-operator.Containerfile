###########################################################################
# Ansible Profiler config update                                          #
###########################################################################

FROM quay.io/operator-framework/ansible-operator:v1.38.1 as builder

# Any file has to be modified in a previous builder stage to avoid the HasModifiedFiles error
# https://docs.redhat.com/en/documentation/red_hat_software_certification/2024/html-single/red_hat_openshift_software_certification_policy_guide/index#con-image-content-requirements_openshift-sw-cert-policy-container-images
RUN cp /etc/ansible/ansible.cfg ${HOME}/ansible-profiler.cfg && echo "callback_enabled = profile_tasks" >> ${HOME}/ansible-profiler.cfg

###########################################################################
# Kiali Operator image                                                    #
###########################################################################

FROM quay.io/operator-framework/ansible-operator:v1.38.1

ARG KIALI_OPERATOR_GIT_TAG \
    KIALI_OPERATOR_GIT_SHA \
    KIALI_OPERATOR_GIT_URL \
    # USER_UID is the ansible UID that is defined by the base image
    USER_UID=${USER_UID}

# Name must match the repository name
LABEL com.github.url="${KIALI_OPERATOR_GIT_URL}" \
      com.github.commit="${KIALI_OPERATOR_GIT_SHA}" \
      summary="Kiali Operator" \
      description="Operator for installing Kiali" \
      version="${KIALI_OPERATOR_GIT_TAG}" \
      io.k8s.display-name="Kiali Operator" \
      io.k8s.description="Operator for installing Kiali"

RUN pip install jmespath kubernetes

# Copy the playbooks, roles and watches into the home folder
COPY kiali-operator/playbooks ${HOME}/playbooks
COPY kiali-operator/watches-k8s.yaml ${HOME}/watches-k8s.yaml
COPY kiali-operator/watches-os.yaml ${HOME}/watches-os.yaml
COPY kiali-operator/watches-k8s-ns.yaml ${HOME}/watches-k8s-ns.yaml
COPY kiali-operator/watches-os-ns.yaml ${HOME}/watches-os-ns.yaml
COPY kiali-operator/roles ${HOME}/roles

# Copy the Kiali operator license
COPY kiali-operator/LICENSE /licenses/LICENSE

# Copy the modified ansible-profiles config from the previous builder stage
COPY --from=builder --chown=${USER_UID}:${USER_UID} ${HOME}/ansible-profiler.cfg ${HOME}/ansible-profiler.cfg

# Ensure we run as ansible non-root user
USER ${USER_UID}