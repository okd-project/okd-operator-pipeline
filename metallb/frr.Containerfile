FROM registry.access.redhat.com/ubi9/go-toolset:1.24 AS builder

COPY --chown=default .git/ .git/

COPY --chown=default ./metallb/frr ./metallb/frr

WORKDIR $HOME/metallb/frr/frr-tools/metrics
RUN CGO_ENABLED=0 GO111MODULE=on go build -mod=vendor -o ./frr-metrics
WORKDIR $HOME/metallb/frr/frr-tools/status
RUN CGO_ENABLED=0 GO111MODULE=on go build -mod=vendor -o ./frr-status

WORKDIR $HOME/metallb/frr/cmd
RUN export SOURCE_GIT_COMMIT="${SOURCE_GIT_COMMIT:-$(git rev-parse --verify 'HEAD^{commit}')}" && \
      export GIT_BRANCH="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}" && \
      CGO_ENABLED=0 GO111MODULE=on go build -mod=vendor -o ./frr-k8s \
      -ldflags "-X frr-k8s/internal/version.gitCommit=${SOURCE_GIT_COMMIT} \
      -X frr-k8s/internal/version.gitBranch=${GIT_BRANCH}"


# When running as non root and building in an environment that `umask` masks out
# '+x' for others, it won't be possible to execute. Make sure all can execute,
# just in case
WORKDIR $HOME/metallb/frr/frr-tools/reloader
RUN chmod a+x frr-reloader.sh

FROM quay.io/centos/centos:stream9
USER root

ARG BUILD_SRC=/opt/app-root/src

COPY --from=builder $BUILD_SRC/metallb/frr/cmd/frr-k8s \
    $BUILD_SRC/metallb/frr/frr-tools/reloader/frr-reloader.sh \
    $BUILD_SRC/metallb/frr/frr-tools/metrics/frr-metrics \
    $BUILD_SRC/metallb/frr/frr-tools/status/frr-status /

ENV PYTHONDONTWRITEBYTECODE yes

RUN INSTALL_PKGS=" \
	tcpdump libpcap \
	iproute iputils strace socat \
    frr \
	python3 \
	podman-catatonit" && \
	yum install -y --setopt=tsflags=nodocs --setopt=skip_missing_names_on_install=False $INSTALL_PKGS

RUN dnf -y update && yum clean all && rm -rf /var/cache/yum/* && rm -rf /var/cache/yum

# frr.sh is the entry point. This script examines environment
# variables to direct operation and configure ovn
ADD ./metallb/frr/frr.sh /root/
ADD ./metallb/frr/daemons /etc/frr
ADD ./metallb/frr/frr.conf /etc/frr
ADD ./metallb/frr/vtysh.conf /etc/frr

RUN chown frr:frr /etc/frr/daemons /etc/frr/frr.conf

RUN ln -s /usr/libexec/podman/catatonit /sbin/tini
RUN usermod -a -G frrvty frr

COPY ./metallb/frr/docker-start /usr/libexec/frr/docker-start
RUN cp -r /usr/libexec/frr /usr/lib/ # required because of the different path on rhel

WORKDIR /root
ENTRYPOINT ["/sbin/tini", "--"]

COPY ./metallb/frr/docker-start /usr/lib/frr/docker-start
CMD ["/usr/lib/frr/docker-start"]
