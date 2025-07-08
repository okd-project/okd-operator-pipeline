###########################################################################
# Kiali UI build                                                          #
###########################################################################

FROM registry.access.redhat.com/ubi9/nodejs-20 AS uibuilder

ARG KIALI_GIT_SHA

# Environment variables
ENV KIALI_ENV=production

# Run as root to install yarn
USER 0

WORKDIR /src/yarn

# Install yarn
RUN npm install -g yarn && \
    \
    # Show node and yarn versions
    node --version && \
    yarn --version

WORKDIR /src/kiali

# Copy the Kiali frontend source code
COPY kiali/frontend .

# Add the git commit sha to package.json
RUN sed -i "s|\$(git rev-parse HEAD)|${KIALI_GIT_SHA}|g" package.json && \
    \
    # Build the Kiali frontend
    yarn install --frozen-lockfile --ignore-scripts && \
    yarn build && \
    \
    # Move the Kiali console to a temporal folder
    mv ./build /tmp/console && \
    rm -rf /src

###########################################################################
# Kiali Server build                                                      #
###########################################################################

FROM registry.access.redhat.com/ubi9/go-toolset:1.23 AS gobuilder

ARG KIALI_GIT_TAG \
    KIALI_GIT_SHA

# Copy the Kiali source code
COPY --chown=default kiali .

# Environment variables
ENV CGO_ENABLED=1 \
    GOEXPERIMENT=strictfipsruntime \
    GOFLAGS="-mod=readonly"

# Build the Kiali server
RUN go version && \
    go build -o /tmp/kiali-unstripped -ldflags "-X main.version=${KIALI_GIT_TAG} -X main.commitHash=${KIALI_GIT_SHA} -X main.goVersion=$(go version 2>/dev/null | grep -Eo  '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" -tags strictfipsruntime && \
    \
    # Compress go binaries
    strip -o /tmp/kiali -s /tmp/kiali-unstripped

###########################################################################
# Kiali Server image                                                      #
###########################################################################

FROM quay.io/centos/centos:stream9-minimal

ARG KIALI_GIT_TAG \
    KIALI_GIT_SHA \
    KIALI_GIT_URL \
    # 1000 is widely used as non-root user
    USER_UID=1000

# Name must match the repository name
LABEL com.github.url="${KIALI_GIT_URL}" \
      com.github.commit="${KIALI_GIT_SHA}" \
      summary="Kiali Service Mesh Observation" \
      description="Microservices mesh observation tool for OKD and Kubernetes" \
      version="${KIALI_GIT_TAG}" \
      io.k8s.display-name="Kiali Service Mesh Observation" \
      io.k8s.description="Microservices mesh observation tool for OKD and Kubernetes"

ENV KIALI_CONTAINER_VERSION="${KIALI_GIT_TAG}"

WORKDIR /opt/kiali

# Add the kiali user and group
RUN echo kiali:x:${USER_UID}: >> /etc/group && \
    echo kiali:x:${USER_UID}:${USER_UID}:/home/kiali:/sbin/nologin >> /etc/passwd

# Copy the Kiali server and console from the previous builder stages
COPY --from=uibuilder --chown=${USER_UID}:${USER_UID} /tmp/console ./console
COPY --from=gobuilder --chown=${USER_UID}:${USER_UID} /tmp/kiali ./kiali

# Copy the Kiali license
COPY kiali/LICENSE /licenses/LICENSE

EXPOSE 20001

# Ensure we do not run as root
USER ${USER_UID}

ENTRYPOINT ["/opt/kiali/kiali"]
