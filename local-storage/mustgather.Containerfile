FROM quay.io/centos/centos:stream9-minimal

COPY ./operator/must-gather/gather /usr/bin/
RUN chmod +x /usr/bin/gather

ENTRYPOINT /usr/bin/gather