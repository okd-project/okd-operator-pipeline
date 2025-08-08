FROM registry.access.redhat.com/ubi9/ubi:latest AS builder

COPY ./vector /src/
WORKDIR /src

RUN INSTALL_PKGS=" \
      gcc-c++ \
      cmake \
      make \
      git \
      openssl-devel \
      llvm-toolset \
      cyrus-sasl \
      llvm \
      cyrus-sasl-devel \
      libtool \
      " && \
    dnf install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    dnf clean all

ENV HOME=/root
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.75.0 -y
ENV CARGO_HOME=$HOME/.cargo
ENV PATH=$CARGO_HOME/bin:$PATH

RUN PROTOC=/src/thirdparty/protoc/protoc-linux-$(arch) make build

FROM quay.io/centos/centos:stream9

# No weak dependencies
RUN dnf install --setopt=nodocs -y systemd \
    && dnf clean all

COPY --from=builder /src/target/release/vector /usr/bin/

WORKDIR /usr/bin
CMD ["/usr/bin/vector"]

LABEL io.k8s.description="Vector container for collection of container logs" \
      io.k8s.display-name="Vector"
