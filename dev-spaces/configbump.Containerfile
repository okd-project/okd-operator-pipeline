FROM registry.access.redhat.com/ubi9/go-toolset:1.25 as builder
USER 0
ENV GOPATH=/go/ \
    CGO_ENABLED=1

WORKDIR /app
COPY ./configbump/ ./

RUN export ARCH="$(uname -m)" && \
    if [[ ${ARCH} == "x86_64" ]]; then export ARCH="amd64"; \
    elif [[ ${ARCH} == "aarch64" ]]; then export ARCH="arm64"; fi && \
    go mod download && go mod verify && \
    go test -v ./... && \
    GOOS=linux GOARCH=${ARCH} go build -a -ldflags '-w -s' -a -installsuffix cgo \
        -o configbump cmd/configbump/main.go && \
    cp configbump /usr/local/bin/configbump && \
    chmod 755 /usr/local/bin/configbump

FROM registry.access.redhat.com/ubi9-minimal:9.7 as runtime
RUN adduser appuser
RUN mkdir /licenses
COPY ./configbump/LICENSE /licenses/LICENSE
USER appuser
COPY --from=builder /usr/local/bin/configbump /usr/local/bin/configbump
ENTRYPOINT ["/usr/local/bin/configbump"]
