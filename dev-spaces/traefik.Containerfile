FROM registry.access.redhat.com/ubi9/go-toolset:1.25 as builder
USER 0

COPY ./traefik /traefik
# webui lives inside the traefik repo; copy explicitly to match upstream build context layout
COPY ./traefik/webui /traefik/webui

WORKDIR /traefik

ENV CGO_ENABLED=1
RUN go build -mod=mod ./cmd/traefik

FROM registry.access.redhat.com/ubi9-minimal:9.7

COPY --from=builder /traefik/traefik /traefik

RUN chmod 755 /traefik

RUN /traefik -h

USER 1001

EXPOSE 80
VOLUME ["/tmp"]
ENTRYPOINT ["/traefik"]
