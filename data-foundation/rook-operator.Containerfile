ARG CEPH_IMG

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 as builder

ARG CI_VERSION

COPY --chown=default ./rook .

RUN go version | tee -a ./go.version

RUN GOOS=linux go build -compiler gc -tags ceph_preview -ldflags "-v -n -X github.com/rook/rook/pkg/version.Version=${CI_VERSION}" -a -v -x -o bin/rook ./cmd/rook

# create rook container
FROM $CEPH_IMG

# Update the image to get the latest CVE updates (if possible)
RUN microdnf install -y jq iproute

USER 1000

COPY --from=builder /opt/app-root/src/bin/rook /usr/local/bin/
COPY --from=builder /opt/app-root/src/images/ceph/toolbox.sh /usr/local/bin/
COPY --from=builder /opt/app-root/src/images/ceph/set-ceph-debug-level /usr/local/bin/
COPY --from=builder /opt/app-root/src/deploy/examples/monitoring /etc/ceph-monitoring
COPY --from=builder /opt/app-root/src/deploy/examples/create-external-cluster-resources.py /etc/rook-external/
COPY --from=builder /opt/app-root/src/go.version /go.version


LABEL description="OKD Data Foundation Rook container" \
    summary="Provides the latest Rook package for OKD Data Foundation." \
    io.k8s.display-name="Rook Ceph Orchestrator"

ENTRYPOINT ["/usr/local/bin/rook"]
CMD [""]