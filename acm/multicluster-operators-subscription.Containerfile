FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-operators-subscription
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS=''
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default acm/multicloud-operators-subscription acm/multicloud-operators-subscription
COPY --chown=default .git .git

WORKDIR $HOME/acm/multicloud-operators-subscription/

RUN GOFLAGS='-p=4' make build


FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS helm-builder

ENV GOFLAGS=''

COPY --chown=default acm/multicloud-operators-subscription/external/helm acm/multicloud-operators-subscription/external/helm
COPY --chown=default .git .git

WORKDIR $HOME/acm/multicloud-operators-subscription/external/helm

RUN CGO_ENABLED=1 VERSION=v3.11.3 make build


FROM registry.access.redhat.com/ubi8/go-toolset:1.23 AS plugin-builder-rhel8

ENV GOFLAGS=''

COPY --chown=default acm/multicloud-operators-subscription/external/policy-generator-plugin acm/multicloud-operators-subscription/external/policy-generator-plugin
COPY --chown=default .git .git

WORKDIR $HOME/acm/multicloud-operators-subscription/external/policy-generator-plugin

# Build a RHEL8 binary with greater compatibility that can be mounted to other containers
RUN make build-binary
RUN mv PolicyGenerator PolicyGenerator-rhel8


FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS plugin-builder

ENV GOFLAGS=''

COPY --chown=default acm/multicloud-operators-subscription/external/policy-generator-plugin acm/multicloud-operators-subscription/external/policy-generator-plugin
COPY --chown=default .git .git

WORKDIR $HOME/acm/multicloud-operators-subscription/external/policy-generator-plugin

RUN make build-binary


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

#RUN  microdnf update -y \
#        && rpm -e --nodeps tzdata \
#        && microdnf install tzdata \
#        && microdnf install git-core \
#        && microdnf install openssh-clients \
#        &&  microdnf clean all

RUN microdnf update -y &&  microdnf clean all
RUN rpm -e --nodeps tzdata
RUN microdnf install tzdata git-core openssh-clients -y &&  microdnf clean all

ENV OPERATOR=/usr/local/bin/multicluster-operators-subscription \
    USER_UID=1001 \
    USER_NAME=multicluster-operators-subscription \
    ZONEINFO=/usr/share/timezone \
    KUSTOMIZE_PLUGIN_HOME=/etc/kustomize/plugin \
    POLICY_GEN_ENABLE_HELM=true \
    SRC_DIR=/opt/app-root/src/acm/multicloud-operators-subscription

# install operator binary
COPY --from=builder $SRC_DIR/build/_output/bin/multicluster-operators-subscription ${OPERATOR}

#COPY --from=builder $SRC_DIR/build/_output/bin/multicluster-operators-placementrule /usr/local/bin
#COPY --from=builder $SRC_DIR/build/_output/bin/appsubsummary /usr/local/bin
#COPY --from=builder $SRC_DIR/build/_output/bin/uninstall-crd /usr/local/bin/uninstall-crd
COPY --from=builder $SRC_DIR/build/_output/bin/multicluster-operators-placementrule /usr/local/bin/
COPY --from=builder $SRC_DIR/build/_output/bin/appsubsummary /usr/local/bin/
COPY --from=builder $SRC_DIR/build/_output/bin/uninstall-crd /usr/local/bin/

COPY --from=builder $SRC_DIR/build/bin /usr/local/bin

# install helm binary
COPY --from=helm-builder $SRC_DIR/external/helm/bin/helm /usr/local/bin/

# install the policy generator Kustomize plugin
RUN mkdir -p $KUSTOMIZE_PLUGIN_HOME/policy.open-cluster-management.io/v1/policygenerator
COPY --from=plugin-builder $SRC_DIR/external/policy-generator-plugin/PolicyGenerator $KUSTOMIZE_PLUGIN_HOME/policy.open-cluster-management.io/v1/policygenerator/PolicyGenerator

# make availabe a RHEL8 policy generator binary for mounting in other containers
RUN mkdir /policy-generator
COPY --from=plugin-builder-rhel8 $SRC_DIR/external/policy-generator-plugin/PolicyGenerator-rhel8 /policy-generator/
# Symlink to the old binary name for compatibility
RUN ln -s /policy-generator/PolicyGenerator-rhel8 /policy-generator/PolicyGenerator-not-fips-compliant

RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}

LABEL summary="multicluster-operators-subscription" \
      io.k8s.display-name="multicluster-operators-subscription" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-operators-subscription"

