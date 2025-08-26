FROM registry.access.redhat.com/ubi9:latest


ENV NAME="ubi9/memcached"
ENV VERSION="1.6"
ENV SUMMARY="High-performance memory object caching system"
ENV DESCRIPTION="memcached is a high-performance, distributed memory object \
		 caching system, generic in nature, but intended for use in \
		 speeding up dynamic web applications by alleviating database \
		 load."

LABEL name="$NAME"
LABEL version="$VERSION"
LABEL summary="$SUMMARY"
LABEL description="$DESCRIPTION"
LABEL usage="podman run -d --name memcached -p 11211:11211 $NAME"
LABEL maintainer="maintainers@okd.io"
LABEL io.k8s.description="$DESCRIPTION"
LABEL io.k8s.display-name="memcached $VERSION"
LABEL io.openshift.expose-services="11211:memcached"
LABEL io.openshift.tags="memcached"

EXPOSE 11211

RUN dnf install -y memcached && \
    install -D /usr/share/doc/memcached/COPYING /licenses/memcached && \
    dnf clean all

COPY memcached /usr/bin/

USER memcached

ENTRYPOINT ["/usr/bin/container-entrypoint"]
