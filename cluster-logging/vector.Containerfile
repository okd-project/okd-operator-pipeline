FROM registry.access.redhat.com/ubi9/ubi:latest AS builder

RUN INSTALL_PKGS=" \
      gcc-c++ \
      cmake \
      make \
      git \
      perl \
      unzip \
      openssl-devel \
      llvm-toolset \
      cyrus-sasl \
      llvm \
      cyrus-sasl-devel \
      libtool \
      crypto-policies-scripts \
      " && \
    dnf install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    dnf clean all

RUN update-crypto-policies --set DEFAULT:PQ

ENV HOME=/root
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.92.0 -y
ENV CARGO_HOME=$HOME/.cargo
ENV PATH=$CARGO_HOME/bin:$PATH

RUN mkdir -p /src

WORKDIR /src
COPY ./vector /src/
RUN /src/scripts/environment/install-protoc.sh
RUN make build

# Strip binary to reduce image size for DaemonSet deployment
RUN strip --strip-all /src/target/release/vector

FROM quay.io/centos/centos:stream9

# No weak dependencies
RUN dnf install --setopt=nodocs -y systemd crypto-policies-scripts \
    && dnf clean all

# Enable post-quantum cryptography, as the builder does
RUN update-crypto-policies --set DEFAULT:PQ

COPY --from=builder /src/target/release/vector /usr/bin/

WORKDIR /usr/bin
CMD ["/usr/bin/vector"]

LABEL io.k8s.description="Vector container for collection of container logs" \
      io.k8s.display-name="Vector"
