# Build che-machine-exec for UBI8 user containers
FROM registry.access.redhat.com/ubi8/go-toolset:1.25 AS builder-machine-exec-ubi8
ENV GOPATH=/go/
ENV CGO_ENABLED=1
USER root
COPY ./che-machine-exec /che-machine-exec
WORKDIR /che-machine-exec
RUN GOOS=linux go build -mod=vendor -a -ldflags '-w -s' -a -installsuffix cgo -o che-machine-exec .

# Build che-machine-exec for UBI9 user containers
FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS builder-machine-exec-ubi9
ENV GOPATH=/go/
ENV CGO_ENABLED=1
USER root
COPY ./che-machine-exec /che-machine-exec
WORKDIR /che-machine-exec
RUN GOOS=linux go build -mod=vendor -a -ldflags '-w -s' -a -installsuffix cgo -o che-machine-exec .

# Build the Che IntelliJ integration plugin (Kotlin/Gradle project)
FROM registry.access.redhat.com/ubi9/openjdk-21:latest AS che-integration-plugin-builder
USER root
RUN microdnf install -y git && microdnf clean all
COPY ./jetbrains-ide-dev-server/che-integration-plugin /che-integration-plugin
WORKDIR /che-integration-plugin
RUN ./gradlew buildPlugin --no-daemon -x test 2>&1 | tail -5 && \
    ls build/distributions/

# Node.js binary from UBI8 for UBI8-based user containers
FROM registry.access.redhat.com/ubi8/nodejs-20:latest as ubi8

# Final image
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:9.7

USER 0

RUN microdnf -y --setopt=install_weak_deps=0 --nodocs install unzip gzip && \
    microdnf clean all

COPY jetbrains-ide-dev-server/build/scripts/*.sh /

COPY jetbrains-ide-dev-server/status-app/ /status-app/

RUN mkdir -p /idea-server/status-app

WORKDIR /status-app
RUN npm install

RUN mkdir /licenses
COPY jetbrains-ide-dev-server/LICENSE /licenses

# Copy the che-integration-plugin zip (IDE plugin that provides Che workspace integration)
COPY --from=che-integration-plugin-builder /che-integration-plugin/build/distributions/che-integration-plugin-*.zip /plugin.zip
RUN unzip /plugin.zip -d /ide-plugin/ && rm /plugin.zip

# Copy libbrotli for UBI9-based user containers that may not have it
RUN mkdir /node-ubi9-ld_libs && cp -r /usr/lib64/libbrotli* /usr/lib64/libcrypto.so.3* /node-ubi9-ld_libs/ || true

# Node.js binary from UBI8 for UBI8-based user containers
COPY --from=ubi8 /usr/bin/node /node-ubi8

COPY --from=builder-machine-exec-ubi8 --chown=0:0 /che-machine-exec/che-machine-exec /machine-exec-bin/machine-exec-ubi8
COPY --from=builder-machine-exec-ubi9 --chown=0:0 /che-machine-exec/che-machine-exec /machine-exec-bin/machine-exec-ubi9

RUN for f in "${HOME}" "/etc/passwd" "/etc/group" "/status-app" "/idea-server"; do \
        if [ "$f" != "/etc/passwd" ]; then \
            chgrp -R 0 "$f" && chmod -R g+rwX "$f"; \
        else \
            chmod -R g-w "$f"; \
        fi; \
    done

USER 1001
ENTRYPOINT /entrypoint.sh
