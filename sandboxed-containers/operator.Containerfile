# OKD build of the OpenShift sandboxed containers operator.
# Adapted from the upstream Dockerfile: both base images are already public UBI
# images (kept, using floating public tags instead of internal build-pinned ones),
# all real build steps are preserved, and the Red Hat LABEL block is dropped.
# Build context is ./operator.
FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder

# Required by the ubi based go-toolset image
USER root

WORKDIR /workspace

COPY Makefile Makefile
COPY hack hack/
COPY PROJECT PROJECT
COPY go.mod go.mod
COPY go.sum go.sum
COPY cmd/ cmd/
COPY api api/
COPY config config/
COPY controllers controllers/

# Copy our controller-gen script to work around hermetic build issues
# See comments in the script itself for more details.
COPY controller-gen bin/

# get the version of controller-gen in an env variable for reusing
RUN echo "export CONTROLLER_TOOLS_VERSION=$(grep -m 1 controller-tools go.mod | awk '{print $2}')" > controller-tools-ver

# rename the script to use the same version as defined in our go.mod file
RUN . ./controller-tools-ver && mv bin/controller-gen bin/controller-gen-$CONTROLLER_TOOLS_VERSION

# make sure 'make' uses the right version of controller-gen
RUN . ./controller-tools-ver && make build

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
WORKDIR /
COPY --from=builder /workspace/bin/manager .
COPY --from=builder /workspace/bin/metrics-server .
COPY --from=builder /workspace/config/peerpods /config/peerpods

RUN useradd  -r -u 499 nonroot
RUN getent group nonroot || groupadd -o -g 499 nonroot

USER 499:499
ENTRYPOINT ["/manager"]
