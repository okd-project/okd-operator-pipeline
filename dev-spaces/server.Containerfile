# Build the Che server assembly from source using Maven.
# The RH downstream build uses a pre-built tarball via cachi2; here we build from source.
FROM registry.access.redhat.com/ubi9/openjdk-17:latest AS maven-builder

USER root

RUN microdnf install -y maven git && microdnf clean all

COPY ./che-server/ /che-server/
WORKDIR /che-server

RUN mvn -T 4 clean package -DskipTests \
        -Dskip.validate.http.artifacts=true \
        -Dlicense.skip=true \
        -Dskip.validate.license.headers=true \
        -Dmaven.repo.local=/tmp/m2 \
        --no-transfer-progress

# The assembly main tarball is produced at assembly/assembly-main/target/
RUN ls assembly/assembly-main/target/*.tar.gz | head -1 && \
    cp $(ls assembly/assembly-main/target/*.tar.gz | head -1) /tmp/assembly-main.tar.gz

FROM registry.access.redhat.com/ubi9-minimal:9.7

USER root

RUN microdnf install -y tar java-17-openjdk && microdnf clean all

RUN adduser -G root user && mkdir -p /home/user/devspaces
COPY --from=maven-builder /tmp/assembly-main.tar.gz /tmp/assembly-main.tar.gz
RUN tar xzf /tmp/assembly-main.tar.gz --strip-components=1 -C /home/user/devspaces && \
    rm -f /tmp/assembly-main.tar.gz

ENV CHE_HOME=/home/user/devspaces
ENV JAVA_HOME=/usr/lib/jvm/jre

RUN mkdir /logs /data && \
    chmod 0777 /logs /data && \
    chgrp -R 0 /home/user /logs /data && \
    chown -R user /home/user && \
    chmod -R g+rwX /home/user && \
    find /home/user -type d -exec chmod 777 {} \;

COPY ./che-server/build/dockerfiles/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

USER user
