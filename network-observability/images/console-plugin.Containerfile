ARG BUILDVERSION
ARG BUILDVERSION_Y

FROM registry.access.redhat.com/ubi9/nodejs-22:latest as web-builder

WORKDIR /opt/app-root

COPY  --chown=default web/package.json web/package.json
COPY  --chown=default web/package-lock.json web/package-lock.json
WORKDIR /opt/app-root/web

RUN CYPRESS_INSTALL_BINARY=0 node --max-old-space-size=6000 $(which npm) --legacy-peer-deps ci --ignore-scripts

WORKDIR /opt/app-root
COPY  --chown=default web web
COPY  --chown=default mocks mocks

WORKDIR /opt/app-root/web
RUN npm run format-all
RUN npm run build
RUN npm run build:static

FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as go-builder

ARG BUILDVERSION

WORKDIR /opt/app-root

COPY go.mod go.mod
COPY go.sum go.sum
COPY vendor/ vendor/
COPY cmd/ cmd/
COPY pkg/ pkg/

ENV GOEXPERIMENT strictfipsruntime
RUN go build -tags strictfipsruntime -ldflags "-X 'main.buildVersion=$BUILDVERSION' -X 'main.buildDate=`date +%Y-%m-%d\ %H:%M`'" -mod vendor -o plugin-backend cmd/plugin-backend.go

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
ARG BUILDVERSION
ARG BUILDVERSION_Y

COPY --from=web-builder /opt/app-root/web/dist ./web/dist
COPY --from=go-builder /opt/app-root/plugin-backend ./
COPY LICENSE /licenses/

USER 65532:65532

ENTRYPOINT ["./plugin-backend"]

LABEL distribution-scope="public"
LABEL url="https://github.com/okd-project/okderators-catalog-index"
LABEL vendor="OKD Community"
LABEL release=$BUILDVERSION
LABEL io.k8s.display-name="Network Observability Console Plugin"
LABEL io.k8s.description="Network Observability Console Plugin"
LABEL summary="Network Observability Console Plugin"
LABEL maintainer="maintainers@okd.io"
LABEL io.openshift.tags="network-observability-console-plugin"
LABEL description="Network Observability visualization tool for the OKD Console."
LABEL version=$BUILDVERSION
