# Derived from migtools/filebrowser Containerfile, not konflux.Dockerfile: the VM file restore
# controller runs this image with /bin/bash -c and a script that calls /usr/local/bin/filebrowser,
# so bash and that path are a contract.

FROM registry.access.redhat.com/ubi9/nodejs-24:latest AS frontend-deps

USER 0
WORKDIR /app

RUN npm install -g pnpm@10.29.2

COPY ./filebrowser/frontend/package.json ./filebrowser/frontend/pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile


FROM registry.access.redhat.com/ubi9/nodejs-24:latest AS frontend-builder

USER 0
WORKDIR /app

RUN npm install -g pnpm@10.29.2

COPY --from=frontend-deps /app/node_modules ./node_modules

COPY ./filebrowser/frontend/ ./

RUN pnpm run build


FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS backend-builder

ARG CI_VERSION=dev

COPY --chown=default ./filebrowser .

COPY --chown=default --from=frontend-builder /app/dist ./frontend/dist

# dist/* is embedded and dist/.gitkeep is committed, so without the frontend the Go build
# still succeeds, silently producing a binary with no UI. The backend serves public/index.html
# under dist; dist/index.html is only Vite's raw copy of it.
RUN test -f frontend/dist/public/index.html

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w \
    -X 'github.com/filebrowser/filebrowser/v2/version.Version=${CI_VERSION}'" \
    -o filebrowser .


FROM registry.access.redhat.com/ubi9-minimal:latest

RUN microdnf install -y --nodocs \
        ca-certificates \
        tzdata \
        shadow-utils \
        curl-minimal && \
    microdnf clean all && \
    rm -rf /var/cache/yum

RUN groupadd -g 1001 filebrowser && \
    useradd -u 1001 -g filebrowser -s /sbin/nologin -M filebrowser && \
    mkdir -p /srv /config /database && \
    chown -R 1001:1001 /srv /config /database

COPY --from=backend-builder --chown=1001:1001 /opt/app-root/src/filebrowser /usr/local/bin/filebrowser

COPY --chown=1001:1001 ./filebrowser/docker/ubi/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

USER 1001

VOLUME ["/srv", "/config", "/database"]

EXPOSE 8080

HEALTHCHECK --start-period=5s --interval=30s --timeout=3s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

ENTRYPOINT ["/usr/local/bin/filebrowser"]
CMD []

LABEL \
        license="Apache License 2.0" \
        io.k8s.display-name="OADP VM File Restore File Browser" \
        io.k8s.description="OKD API for Data Protection - web-based file browser for VM file restore" \
        summary="OKD API for Data Protection - VM File Restore File Browser" \
        maintainer="OKD Community <maintainers@okd.io>"
