ARG IMG_CLI

FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as builder

ARG CI_VERSION

ENV GOFLAGS=''

COPY --chown=default ./cloudnative-pg .

# Apply downstream changes for inclusion in NooBaa/mcg bundle
RUN find . -name .git -a -type d -prune -o -type f -exec \
    sed -i -e 's|postgresql.cnpg.io|postgresql.cnpg.noobaa.io|g' -e 's|postgresql-cnpg-io|postgresql-cnpg-noobaa-io|g' {} +

RUN go version | tee -a go.version

#Hack to change Go to 1.23.5 from 1.23.4 while building
#RUN sed -i 's/go 1.23.*/go 1.23.2/g' go.mod

RUN GOOS=linux go build -a -o manager -ldflags "-X github.com/cloudnative-pg/cloudnative-pg/pkg/versions.buildVersion=${CI_VERSION} -X github.com/cloudnative-pg/cloudnative-pg/pkg/versions.buildCommit=$(git rev-parse --short HEAD)$()" cmd/manager/main.go
RUN GOOS=linux go build -a -o kubectl-cnpg -ldflags "-X github.com/cloudnative-pg/cloudnative-pg/pkg/versions.buildVersion=${CI_VERSION} -X github.com/cloudnative-pg/cloudnative-pg/pkg/versions.buildCommit=$(git rev-parse --short HEAD)" ./cmd/kubectl-cnpg

# Build stage 2
FROM $IMG_CLI
ARG TARGETARCH

ENV OPBIN=/operator/manager_$TARGETARCH

COPY --from=builder /opt/app-root/src/manager "$OPBIN"
COPY --from=builder /opt/app-root/src/kubectl-cnpg "/usr/bin/kubectl-cnpg"
COPY --from=builder /opt/app-root/src/go.version /go.version

LABEL maintainer="OKD Community <maintainers@okd.io>"
LABEL description="OKD Data Foundation CloudnativePG Operator"
LABEL summary="Provides the latest CloudnativePG operator container for OKD Data Foundation"
LABEL io.k8s.display-name="ODF Cloudnative PG Operator"
LABEL io.k8s.description="OpenShift Data Foundation CloudnativePG operator to manage PostgreSQL databases"

RUN chmod +x "$OPBIN"
RUN ln -sf "$OPBIN" /manager

ENTRYPOINT ["/manager"]