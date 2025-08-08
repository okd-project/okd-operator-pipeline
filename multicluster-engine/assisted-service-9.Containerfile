ARG IMG_CLI

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS go-builder
FROM quay.io/centos/centos:stream9-minimal AS builder

ARG CI_VERSION

ENV COMPONENT_NAME=assisted-service
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV USER_UID=1001 \
    USER_NAME=assisted-installer

WORKDIR /src/
COPY --chown=$USER_UID assisted-service .

RUN INSTALL_PKGS="gcc git nmstate-devel openssl-devel" && \
    sed -i '/^\[crb\]/,/^\[/ s/enabled=0/enabled=1/' /etc/yum.repos.d/centos.repo && \
    microdnf install -y $INSTALL_PKGS && \
    microdnf clean all

# Copy golang resources
COPY --from=go-builder /usr/bin/go /usr/local/bin/go
COPY --from=go-builder /usr/lib/golang /usr/lib/golang

ENV GOROOT=/usr/lib/golang
ENV PATH=$PATH:$GOROOT/bin
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

# RUN go build
RUN CGO_ENABLED=1 GOFLAGS="-p=4" GO111MODULE=on go build -tags ${BUILD_TAGS} -o ./assisted-service cmd/main.go
RUN CGO_ENABLED=1 GOFLAGS="-p=4" GO111MODULE=on go build -tags ${BUILD_TAGS} -o ./assisted-service-operator cmd/operator/main.go
RUN CGO_ENABLED=1 GOFLAGS="-p=4" GO111MODULE=on go build -tags ${BUILD_TAGS} -o ./assisted-service-admission cmd/webadmission/main.go
RUN CGO_ENABLED=1 GOFLAGS="-p=4" GO111MODULE=on go build -tags ${BUILD_TAGS} -o ./agent-installer-client cmd/agentbasedinstaller/client/main.go


FROM $IMG_CLI AS oc-image
# Copy the specific `oc` cli corresponding to the current architecture to an arch-agnostic location
# This will need to be updated periodically as AI changes their dependencies on `oc`
RUN ARCH=$(if [ "$(arch)" == "x86_64" ]; then echo "amd64"; elif [ "$(arch)" == "aarch64" ]; then echo "arm64"; else echo $(arch); fi) && \
    cp -p /usr/share/openshift/linux_${ARCH}/oc /usr/local/bin/oc


FROM quay.io/centos/centos:stream9-minimal

ENV USER_UID=1001 \
    USER_NAME=assisted-installer

COPY --from=builder /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-bundle.crt
COPY --from=builder /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt /etc/ssl/certs/ca-bundle.trust.crt
COPY --from=builder /src/assisted-service /assisted-service
COPY --from=builder /src/assisted-service-operator /assisted-service-operator
COPY --from=builder /src/assisted-service-admission /assisted-service-admission
COPY --from=builder /src/agent-installer-client /usr/local/bin/agent-installer-client
RUN ln -s /usr/local/bin/agent-installer-client /agent-based-installer-register-cluster-and-infraenv

COPY --from=oc-image /usr/local/bin/oc /usr/local/bin

RUN INSTALL_PKGS="libvirt-libs nmstate nmstate-devel nmstate-libs skopeo" && \
    sed -i '/^\[crb\]/,/^\[/ s/enabled=0/enabled=1/' /etc/yum.repos.d/centos.repo && \
    microdnf install -y $INSTALL_PKGS --nobest && \
    microdnf clean all && \
    rm -rf /var/cache/{yum,dnf,microdnf}/* && \
    mkdir -p ${HOME} && \
    chown ${USER_UID}:0 ${HOME} && \
    chmod ug+rwx ${HOME} && \
    # runtime user will need to be able to self-insert in /etc/passwd
    chmod g+rw /etc/passwd

RUN rm -f /etc/pki/tls/certs/ca-bundle.crt
RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/tls/certs/ca-bundle.crt

ENTRYPOINT ["/assisted-service"]

USER ${USER_UID}

LABEL summary="OKD Assisted Installer Service" \
      io.k8s.display-name="OKD Assisted Installer Service" \
      maintainer="OKD Community <maintainers@okd.io>" \
      description="OKD Assisted Installer Service"
