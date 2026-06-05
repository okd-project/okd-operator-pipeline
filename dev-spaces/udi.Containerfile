# Build gopls, kubedock, and stow from source
FROM registry.access.redhat.com/ubi9/go-toolset:1.25 as go-builder

USER root

RUN dnf -y -q install perl perl-App-cpanminus automake autoconf && \
    cpanm --notest Test::Output

COPY ./stow /stow

# Build gopls via go install (internet-connected build)
RUN go install golang.org/x/tools/gopls@latest

# Download kubedock pre-built binary from GitHub releases
# (kubedock master requires Go 1.26+; pre-built binary matches the upstream-pinned version)
RUN ARCH="$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/arm64/')" && \
    curl -fsSL "https://github.com/joyrex2001/kubedock/releases/download/0.21.1/kubedock_linux_${ARCH}.tar.gz" \
         -o /tmp/kubedock.tar.gz && \
    tar -xzf /tmp/kubedock.tar.gz -C /tmp && \
    mv /tmp/kubedock /usr/local/bin/kubedock && \
    chmod +x /usr/local/bin/kubedock && \
    rm /tmp/kubedock.tar.gz

# Build stow — match upstream prefix /stow/build; texinfo unavailable in UBI9 free repos
# so we use make -k to continue past doc targets, then manually populate the prefix tree
RUN mkdir -p /stow/build && \
    cd /stow && \
    rm -rf .git && git init && \
    autoreconf -iv && \
    ./configure --prefix=/stow/build && \
    (make MAKEINFO=true -k 2>/dev/null; true) && \
    mkdir -p /stow/build/bin /stow/build/share/perl5/5.32/Stow && \
    install -m 755 bin/stow /stow/build/bin/stow && \
    cp lib/Stow.pm /stow/build/share/perl5/5.32/ && \
    cp -r lib/Stow/*.pm /stow/build/share/perl5/5.32/Stow/ && \
    PERL5LIB=/stow/build/share/perl5/5.32 /stow/build/bin/stow --version

FROM registry.access.redhat.com/ubi9-minimal:9.7

LABEL io.openshift.expose-services="" \
      usage=""

USER root

COPY ./build/udi/etc/storage.conf /home/tooling/.config/containers/storage.conf
COPY ./build/udi/etc/entrypoint.sh /entrypoint.sh
COPY --chown=0:0 ./build/udi/etc/podman-wrapper.sh /usr/bin/
COPY --chown=0:0 ./build/udi/etc/.stow-local-ignore /home/tooling/
COPY --chown=0:0 ./build/udi/etc/.copy-files /home/tooling/

ENV \
    HOME=/home/tooling \
    NODEJS_VERSION="20" \
    MAVEN_VERSION="3.9" \
    PYTHON_VERSION="3.11" \
    PHP_VERSION="8.1" \
    XDEBUG_VERSION="3.1.6" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    JAVA_HOME_17=/usr/lib/jvm/java-17-openjdk \
    JAVA_HOME_21=/usr/lib/jvm/java-21-openjdk \
    JAVA_HOME="/home/user/.java/current" \
    GOBIN="/home/user/go/bin/" \
    PATH="/home/user/.local/bin:/home/user/.java/current/bin:/home/user/go/bin:/usr/share/maven/bin:/usr/bin:/home/tooling/.local/bin:/home/tooling/.java/current/bin:/home/tooling/go/bin:${PATH:-/bin:/usr/bin}" \
    M2_HOME="/usr/share/maven" \
    _BUILDAH_STARTED_IN_USERNS="" BUILDAH_ISOLATION=chroot

RUN microdnf install -y dnf && \
    dnf -y -q install 'dnf-command(config-manager)' && \
    dnf -y -q module reset maven nodejs php && \
    dnf -y -q module install maven:${MAVEN_VERSION}/common nodejs:${NODEJS_VERSION}/development php:${PHP_VERSION}/devel

RUN dnf -y -q install --setopt=tsflags=nodocs \
        container-tools golang \
        java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless \
        java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless \
        nodejs npm nodejs-nodemon nss_wrapper \
        make cmake gcc gcc-c++ \
        llvm-toolset clang clang-libs clang-tools-extra gdb \
        php php-cli php-fpm php-opcache php-devel php-pear php-gd php-intl php-zlib php-curl \
        python3.11 python3.11-devel python3.11-setuptools python3.11-pip python3.11-wheel \
        libssh-devel libffi-devel cargo openssl-devel pkg-config jq \
        podman buildah skopeo fuse-overlayfs \
        git ca-certificates \
        bash bash-completion tar gzip unzip bzip2 which shadow-utils findutils wget sudo git-lfs procps-ng vim

# Install OKD/OpenShift client tools from public releases
RUN ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" && \
    OC_VERSION="4.21.0-okd-scos.10" && \
    curl -fsSL "https://github.com/okd-project/okd-scos/releases/download/${OC_VERSION}/openshift-client-linux-${ARCH}-${OC_VERSION}.tar.gz" \
         -o /tmp/oc.tar.gz 2>/dev/null && \
    tar -xzf /tmp/oc.tar.gz -C /usr/local/bin/ oc kubectl 2>/dev/null && \
    rm -f /tmp/oc.tar.gz && \
    echo "oc version: $(oc version --client 2>/dev/null | head -1)" || \
    echo "WARNING: Could not install oc client"

RUN dnf -y -q install --setopt=tsflags=nodocs dotnet-sdk-8.0 && \
    dnf config-manager --set-disabled rhocp* 2>/dev/null || true && \
    dnf -y -q reinstall shadow-utils && \
    dnf -y -q update && \
    dnf -y -q clean all --enablerepo='*' && rm -rf /var/cache/yum && \
    mkdir -p /opt && \
    useradd -u 1000 -G wheel,root -d /home/user --shell /bin/bash -m user && \
    cp /home/user/.bashrc /home/tooling/.bashrc && \
    cp /home/user/.bash_profile /home/tooling/.bash_profile && \
    touch /etc/profile.d/udi_environment.sh && \
    touch /etc/profile.d/udi_prompt.sh && \
    echo "export PS1='\W \`git branch --show-current 2>/dev/null | sed -r -e \"s@^(.+)@\(\1\) @\"\`$ '" \
        >> /etc/profile.d/udi_prompt.sh && \
    mkdir -p /projects && \
    for f in "${HOME}" "/etc/passwd" "/etc/group" "/projects"; do \
        chgrp -R 0 ${f} && chmod -R g+rwX ${f}; \
    done && \
    cat /etc/passwd | \
        sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g \
        > ${HOME}/passwd.template && \
    cat /etc/group | \
        sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
        > ${HOME}/group.template && \
    mkdir -p /home/tooling/.local/bin

RUN touch /etc/subgid /etc/subuid && \
    chmod g=u /etc/subgid /etc/subuid /etc/passwd && \
    echo user:10000:65536 > /etc/subuid && \
    echo user:10000:65536 > /etc/subgid && \
    sed -i -e 's|^#mount_program|mount_program|g' \
           -e '/additionalimage.*/a "/var/lib/shared",' \
           /etc/containers/storage.conf && \
    mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers && \
    touch /var/lib/shared/overlay-images/images.lock \
          /var/lib/shared/overlay-layers/layers.lock && \
    mv /usr/bin/podman /usr/bin/podman.orig && \
    echo 'alias docker=podman' >> /etc/profile.d/udi_environment.sh

RUN mkdir -p /home/tooling/.m2 /home/tooling/.config/pip /home/tooling/.cargo \
             /home/tooling/certs /home/tooling/.composer /home/tooling/.nuget && \
    mkdir -p ${HOME}/.java/current && \
    rm -f /usr/bin/java && \
    ln -s /usr/lib/jvm/java-17-openjdk/* ${HOME}/.java/current && \
    SL=/usr/bin/nodemon; if [[ ! -f ${SL} ]] && [[ ! -L ${SL} ]]; then \
        ln -s /usr/lib/node_modules/nodemon/bin/nodemon.js ${SL}; fi && \
    mkdir -p /opt/app-root/src/.npm-global/bin && \
    ln -s /usr/bin/node /usr/bin/nodejs && \
    for f in "/opt/app-root/src/.npm-global"; do chgrp -R 0 ${f}; chmod -R g+rwX ${f}; done

RUN python${PYTHON_VERSION} -m pip install --user --no-cache-dir \
        --upgrade pip setuptools pytest flake8 virtualenv yq && \
    echo -e "#!/usr/bin/bash\n/usr/bin/python${PYTHON_VERSION} -m pip \$*" > /usr/bin/pip && \
    echo -e "#!/usr/bin/bash\n/usr/bin/python${PYTHON_VERSION} -m flake8 \$*" > /usr/bin/flake8 && \
    echo -e "#!/usr/bin/bash\n/usr/bin/python${PYTHON_VERSION} -m pytest \$*" > /usr/bin/pytest && \
    echo -e "#!/usr/bin/bash\n/usr/bin/python${PYTHON_VERSION} -m yq \$*" > /usr/bin/yq && \
    chmod +x /usr/bin/pip /usr/bin/flake8 /usr/bin/pytest /usr/bin/yq && \
    SL=/usr/local/bin/python; [[ ! -f ${SL} && ! -L ${SL} ]] && \
        ln -s /usr/bin/python${PYTHON_VERSION} ${SL} || true && \
    cd /home/tooling && python${PYTHON_VERSION} -m venv .venv

# Build and install xdebug from PECL source
RUN pecl install xdebug-${XDEBUG_VERSION} && \
    echo -e "[xdebug]\nzend_extension=$(find /usr/lib64/php/modules -name xdebug.so)\n\
xdebug.client_port = 9001\nxdebug.mode = debug\nxdebug.start_with_request = yes\n\
xdebug.log=\${HOME}/xdebug.log" >> /etc/php.ini && \
    sed -i 's/opt\/app-root\/src/projects/' /etc/httpd/conf/httpd.conf && \
    chmod -R 777 /var/run/httpd /var/log/httpd/ /etc/pki/ /etc/httpd/logs/ \
        /etc/httpd/conf/httpd.conf /etc/php.ini || true

COPY --from=go-builder /opt/app-root/src/go/bin/gopls ${HOME}/go/bin/gopls
COPY --from=go-builder /usr/local/bin/kubedock ${HOME}/go/bin/kubedock
# Match upstream stow install layout exactly
COPY --from=go-builder /stow/build/bin/ /usr/bin/
COPY --from=go-builder /stow/build/share/ /usr/share/
COPY --from=go-builder /stow/build/share/perl5/5.32/ /usr/share/perl5/vendor_perl/

RUN stow . -t /home/user/ -d /home/tooling/ --no-folding && \
    cp /home/tooling/.viminfo /home/user/.viminfo 2>/dev/null || true

RUN chmod 755 /usr/local/bin/* 2>/dev/null || true && \
    chmod -R g+rwX ${HOME} && \
    chgrp -R 0 /home && chmod -R g=u /home

USER 10001
ENV HOME=/home/user
ENTRYPOINT ["/usr/libexec/podman/catatonit","--","/entrypoint.sh"]
WORKDIR /projects
CMD tail -f /dev/null
