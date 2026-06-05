FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:9.7 AS builder

USER 0
RUN microdnf install -y jq zip git && microdnf clean all

COPY ./che-dashboard/ /dashboard/

# Link yarn from the repo's bundled release
RUN ln -s /dashboard/.yarn/releases/yarn-4.*.*.cjs /usr/bin/yarn

WORKDIR /dashboard
RUN yarn install --mode=skip-build && \
    yarn build

FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:9.7

USER 0

RUN microdnf install -y git && microdnf clean all

ENV FRONTEND_LIB=/dashboard/packages/dashboard-frontend/lib/public
ENV BACKEND_LIB=/dashboard/packages/dashboard-backend/lib
ENV DEVFILE_REGISTRY=/dashboard/packages/devfile-registry

COPY --from=builder ${BACKEND_LIB} /backend
COPY --from=builder ${FRONTEND_LIB} /public
COPY --from=builder ${DEVFILE_REGISTRY} /public/dashboard/devfile-registry

RUN chmod -R ug+rw /public/dashboard/devfile-registry

COPY che-dashboard/build/dockerfiles/rhel.entrypoint.sh /usr/local/bin

USER 1001

CMD ["/usr/local/bin/rhel.entrypoint.sh"]
