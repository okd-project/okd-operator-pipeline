FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS builder

ARG CI_VERSION

ENV USE_VENDORIZED_BUILD_HARNESS=true
ENV COMPONENT_NAME=multicluster-engine-hypershift-cli
ENV COMPONENT_VERSION=$CI_VERSION
ENV COMPONENT_TAG_EXTENSION=" "
ENV GOFLAGS="-p=4"
ENV GOEXPERIMENT=strictfipsruntime
ENV BUILD_TAGS="strictfipsruntime"

COPY --chown=default hypershift .


#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=linux GOARCH=amd64 go build -o $REMOTE_SOURCE_DIR/app/bin/linux/amd64/hcp -tags ${BUILD_TAGS} ./product-cli
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=linux GOARCH=arm64 go build -o $REMOTE_SOURCE_DIR/app/bin/linux/arm64/hcp -tags ${BUILD_TAGS} ./product-cli
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=linux GOARCH=ppc64 go build -o $REMOTE_SOURCE_DIR/app/bin/linux/ppc64/hcp -tags ${BUILD_TAGS} ./product-cli
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=linux GOARCH=ppc64le go build -o $REMOTE_SOURCE_DIR/app/bin/linux/ppc64le/hcp -tags ${BUILD_TAGS} ./product-cli
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=linux GOARCH=s390x go build -o $REMOTE_SOURCE_DIR/app/bin/linux/s390x/hcp -tags ${BUILD_TAGS} ./product-cli
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=darwin GOARCH=amd64 go build -o $REMOTE_SOURCE_DIR/app/bin/darwin/amd64/hcp -tags ${BUILD_TAGS} ./product-cli
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=darwin GOARCH=arm64 go build -o $REMOTE_SOURCE_DIR/app/bin/darwin/arm64/hcp -tags ${BUILD_TAGS} ./product-cli
#RUN CGO_ENABLED=0 GO111MODULE=on GOFLAGS=-mod=vendor GOOS=windows GOARCH=amd64 go build -o $REMOTE_SOURCE_DIR/app/bin/windows/amd64/hcp -tags ${BUILD_TAGS} ./product-cli

RUN CGO_ENABLED=0 GO111MODULE=on GOOS=linux GOARCH=amd64 go build -o ./bin/linux/amd64/hcp -tags ${BUILD_TAGS} ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=linux GOARCH=arm64 go build -o ./bin/linux/arm64/hcp -tags ${BUILD_TAGS} ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=linux GOARCH=ppc64 go build -o ./bin/linux/ppc64/hcp -tags ${BUILD_TAGS} ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=linux GOARCH=ppc64le go build -o ./bin/linux/ppc64le/hcp -tags ${BUILD_TAGS} ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=linux GOARCH=s390x go build -o ./bin/linux/s390x/hcp -tags ${BUILD_TAGS} ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=darwin GOARCH=amd64 go build -o ./bin/darwin/amd64/hcp -tags ${BUILD_TAGS} ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=darwin GOARCH=arm64 go build -o ./bin/darwin/arm64/hcp -tags ${BUILD_TAGS} ./product-cli
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=windows GOARCH=amd64 go build -o ./bin/windows/amd64/hcp -tags ${BUILD_TAGS} ./product-cli

RUN tar -czvf ./bin/linux/amd64/hcp.tar.gz -C ./bin/linux/amd64 ./hcp
RUN tar -czvf ./bin/linux/arm64/hcp.tar.gz -C ./bin/linux/arm64 ./hcp
RUN tar -czvf ./bin/linux/ppc64/hcp.tar.gz -C ./bin/linux/ppc64 ./hcp
RUN tar -czvf ./bin/linux/ppc64le/hcp.tar.gz -C ./bin/linux/ppc64le ./hcp
RUN tar -czvf ./bin/linux/s390x/hcp.tar.gz -C ./bin/linux/s390x ./hcp
RUN tar -czvf ./bin/darwin/amd64/hcp.tar.gz -C ./bin/darwin/amd64 ./hcp
RUN tar -czvf ./bin/darwin/arm64/hcp.tar.gz -C ./bin/darwin/arm64 ./hcp
RUN tar -czvf ./bin/windows/amd64/hcp.tar.gz -C ./bin/windows/amd64 ./hcp



FROM registry.access.redhat.com/ubi9/nginx-122:1-1747323868

ENV REMOTE_SOURCE_DIR=/opt/app-root/src

COPY --from=builder $REMOTE_SOURCE_DIR/bin/linux/amd64/hcp.tar.gz    /opt/app-root/src/linux/amd64/hcp.tar.gz
COPY --from=builder $REMOTE_SOURCE_DIR/bin/linux/arm64/hcp.tar.gz    /opt/app-root/src/linux/arm64/hcp.tar.gz
COPY --from=builder $REMOTE_SOURCE_DIR/bin/linux/ppc64/hcp.tar.gz    /opt/app-root/src/linux/ppc64/hcp.tar.gz
COPY --from=builder $REMOTE_SOURCE_DIR/bin/linux/ppc64le/hcp.tar.gz    /opt/app-root/src/linux/ppc64le/hcp.tar.gz
COPY --from=builder $REMOTE_SOURCE_DIR/bin/linux/s390x/hcp.tar.gz    /opt/app-root/src/linux/s390x/hcp.tar.gz
COPY --from=builder $REMOTE_SOURCE_DIR/bin/darwin/amd64/hcp.tar.gz   /opt/app-root/src/darwin/amd64/hcp.tar.gz
COPY --from=builder $REMOTE_SOURCE_DIR/bin/darwin/arm64/hcp.tar.gz   /opt/app-root/src/darwin/arm64/hcp.tar.gz
COPY --from=builder $REMOTE_SOURCE_DIR/bin/windows/amd64/hcp.tar.gz  /opt/app-root/src/windows/amd64/hcp.tar.gz

CMD ["nginx", "-g", "daemon off;"]


LABEL summary="multicluster-engine-hypershift-cli" \
      io.k8s.display-name="multicluster-engine-hypershift-cli" \
      maintainer="['maintainers@okd.io']" \
      description="multicluster-engine-hypershift-cli"
