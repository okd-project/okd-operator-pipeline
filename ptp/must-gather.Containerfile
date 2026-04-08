ARG IMG_CLI
FROM $IMG_CLI
COPY ./operator/must-gather/collection-scripts/* /usr/bin/
RUN chmod +x /usr/bin/gather

ENTRYPOINT /usr/bin/gather
