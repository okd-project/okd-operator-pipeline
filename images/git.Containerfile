FROM quay.io/centos/centos:stream9-minimal

RUN microdnf update -y && \
    microdnf install -y git && \
    microdnf clean all

RUN useradd build -u 65532 && \
    echo -e "build:1:65531\nbuild:65533:64535" > /etc/subuid && \
    echo -e "build:1:65531\nbuild:65533:64535" > /etc/subgid && \
    chown -R build:build /home/build

WORKDIR /home/build
USER build