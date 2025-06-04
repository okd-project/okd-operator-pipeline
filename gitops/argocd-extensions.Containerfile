# Copyright 2024 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ------------------------------------------------------------------------

####################################################################################################
# Rollouts Extensions UI stage
####################################################################################################
FROM registry.access.redhat.com/ubi9/nodejs-22 as rollout-extensions

COPY --chown=default ./gitops/rollout-extension ./gitops/rollout-extension
COPY --chown=default .git .git

WORKDIR /opt/app-root/src/gitops/rollout-extension/ui

RUN npm install --global yarn@1.22.22 && \
    yarn install --from-lockfile --no-progress --non-interactive && \
    NODE_ONLINE_ENV='offline' NODE_ENV='production' yarn build

####################################################################################################
# Final Image
####################################################################################################
FROM quay.io/centos/centos:stream9-minimal

ARG USER=ext-installer
ENV HOME=/home/$USER

RUN microdnf install -y file jq shadow-utils tar && microdnf clean all

WORKDIR $HOME

COPY --from=rollout-extensions /opt/app-root/src/gitops/rollout-extension/ui/dist/extension.tar rollout-extension.tar
COPY gitops/argocd-extension-installer/install.sh install.sh

ENV EXTENSION_NAME="Rollout"
ENV EXTENSION_URL="file://$HOME/rollout-extension.tar"
ENV EXTENSION_VERSION="0.3.6"

ENTRYPOINT ["./install.sh"]

LABEL \
    License="Apache 2.0" \
    summary="OKD GitOps Argocd Extensions" \
    io.k8s.display-name="OKD GitOps ArgoCD Extensions" \
    maintainer="OKD Community <maintainers@okd.io>" \
    description="OKD GitOps ArgoCD Extensions"