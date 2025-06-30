###########################################################################
# Ztunnel build                                                           #
###########################################################################

# We use 9.4 els image here as UBI won't bring us much benefits as we still need content from subscription.
# We will move to UBI when RHEL 9.7 is available as it will contain rust 1.85.
FROM quay.io/centos/centos:stream9 AS ztunnel_builder

WORKDIR /ztunnel

COPY ztunnel .

RUN dnf config-manager --set-enabled crb
# rpms needed for build preparations
RUN dnf -y install xz
# rpms needed for actual build
RUN dnf -y install openssl-devel gcc protobuf-compiler rust

# Preparation
RUN ARCH=$(uname -p); curl -sL https://static.rust-lang.org/dist/rust-1.85.1-${ARCH}-unknown-linux-gnu.tar.xz | tar -xJ && ./rust-1.85.1-*/install.sh

# Build
RUN cargo build --release --features tls-openssl --no-default-features

###########################################################################
# Ztunnel image                                                           #
###########################################################################

FROM quay.io/centos/centos:stream9-minimal AS ztunnel_release

ARG ZTUNNEL_GIT_TAG
ARG ZTUNNEL_GIT_SHA
ARG ZTUNNEL_GIT_URL

# Name must match the repository name
LABEL com.github.url="${ZTUNNEL_GIT_URL}"
LABEL com.github.commit="${ZTUNNEL_GIT_SHA}"
LABEL summary="OKD Service Mesh Ztunnel OKD container image"
LABEL description="OKD Service Mesh Ztunnel OKD container image"
LABEL version="${ZTUNNEL_GIT_TAG}"
LABEL istio_version="${ZTUNNEL_GIT_TAG}"
LABEL io.k8s.display-name="OKD Service Mesh ZTunnel"
LABEL io.k8s.description="OKD Service Mesh ZTunnel OKD container image"

ENV ISTIO_VERSION="${ZTUNNEL_GIT_TAG}"
ENV container="oci"

# Install openssl library
RUN microdnf install -y openssl && microdnf clean all
RUN ln -s /usr/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so && ln -s /usr/lib64/libssl.so.3 /usr/lib64/libssl.so

COPY --from=ztunnel_builder /ztunnel/out/rust/release/ztunnel /usr/local/bin/ztunnel

# Copy the ztunnel license
COPY ztunnel/LICENSE /licenses/LICENSE

# Ensure we do not run as root
USER 1000

ENTRYPOINT ["/usr/local/bin/ztunnel"]
