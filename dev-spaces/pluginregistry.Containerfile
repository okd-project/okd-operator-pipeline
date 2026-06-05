# Build openvsx server from source (uses Gradle)
FROM registry.access.redhat.com/ubi9/openjdk-25:latest AS openvsx-builder

USER root
RUN microdnf install -y git python3 && microdnf clean all

RUN git clone --depth=1 https://github.com/eclipse/openvsx.git /openvsx

WORKDIR /openvsx/server

# Strip all Gatling (load-testing) and Scala references from the build.
# Gatling is only used for performance simulations and is not needed to
# produce the runnable server JAR.
RUN python3 - <<'PYEOF'
import re, pathlib

def remove_named_block(text, keyword_pattern):
    """Remove 'keyword { ... }' block using brace counting to handle nesting."""
    result = []
    lines = text.splitlines(keepends=True)
    i = 0
    while i < len(lines):
        if re.match(r'\s*' + keyword_pattern + r'\s*\{', lines[i]):
            depth = lines[i].count('{') - lines[i].count('}')
            i += 1
            while i < len(lines) and depth > 0:
                depth += lines[i].count('{') - lines[i].count('}')
                i += 1
        else:
            result.append(lines[i])
            i += 1
    return ''.join(result)

# --- build.gradle ---------------------------------------------------------
bg = pathlib.Path("build.gradle").read_text()

bg = re.sub(r"^\s*id\s+'scala'\s*\n", "", bg, flags=re.MULTILINE)
bg = re.sub(r"^\s*alias\(libs\.plugins\.gatling\)\s*\n", "", bg, flags=re.MULTILINE)
bg = re.sub(r"^\s*gatling\.exclude.*\n", "", bg, flags=re.MULTILINE)
bg = remove_named_block(bg, "gatling")
bg = re.sub(r"^\s*gatling\s+.*\n", "", bg, flags=re.MULTILINE)
bg = remove_named_block(bg, r"tasks\.withType\(ScalaCompile\)\.configureEach")

pathlib.Path("build.gradle").write_text(bg)

# --- libs.versions.toml ---------------------------------------------------
toml = pathlib.Path("gradle/libs.versions.toml").read_text()
toml = re.sub(r"^gatling[\w-]*\s*=.*\n", "", toml, flags=re.MULTILINE)
pathlib.Path("gradle/libs.versions.toml").write_text(toml)

print("Patching complete")
PYEOF

RUN ./gradlew assemble --no-daemon -x test -x jooqCodegen && \
    ls build/libs/

FROM quay.io/centos/centos:stream9

USER 0

RUN dnf -y update && \
    dnf module install postgresql:15/server nodejs:20 -y && \
    dnf -y install postgresql-contrib java-25-openjdk httpd glibc-locale-source jq unzip nss_wrapper passwd shadow-utils findutils npm && \
    dnf -y clean all

RUN mkdir -p /openvsx-server/vsix /openvsx-server/config

COPY --from=openvsx-builder /openvsx/server/build/libs/openvsx-server-*.jar /openvsx-server/openvsx-server.jar
RUN cd /openvsx-server && \
    unzip openvsx-server.jar -d . && \
    rm openvsx-server.jar

COPY ./build/pluginregistry/application.yaml /openvsx-server/config/
COPY ./build/pluginregistry/openvsx-sync.json /openvsx-server/

RUN chmod -R g+rwx /openvsx-server

RUN npm install -g ovsx && ovsx --version

RUN chown root:root /etc/passwd /etc/group && chmod 0644 /etc/passwd /etc/group

RUN mkdir -p /var/log/httpd /run/httpd && \
    chown -R 1001:0 /var/log/httpd /run/httpd && \
    chmod -R g+rwx /var/log/httpd && chmod -R g+rwX /run/httpd

COPY ./build/pluginregistry/scripts/run-server.sh /openvsx-server/
COPY ./build/pluginregistry/scripts/import_vsix.sh /usr/local/bin/
COPY ./build/pluginregistry/scripts/start_services.sh /usr/local/bin/
COPY ./build/pluginregistry/openvsx.conf /etc/httpd/conf.d/
COPY ./build/pluginregistry/scripts/entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/import_vsix.sh \
             /usr/local/bin/start_services.sh \
             /usr/local/bin/entrypoint.sh \
             /openvsx-server/run-server.sh

RUN mkdir -p /var/run/postgresql && \
    chmod 777 /var/run/postgresql && \
    localedef -f UTF-8 -i en_US en_US.UTF-8 && \
    usermod -a -G apache,root,postgres postgres

RUN sed -i /etc/httpd/conf/httpd.conf \
    -e "s,Listen 80,Listen 8080," \
    -e "s,logs/error_log,/dev/stderr," \
    -e "/<IfModule log_config_module>/a SetEnvIf User-Agent \"^kube-probe/\" dontlog" \
    -e 's,CustomLog "logs/access_log" combined,CustomLog /dev/stdout combined env=!dontlog,' \
    -e "s,AllowOverride None,AllowOverride All," && \
    chmod a+rwX /etc/httpd/conf /etc/httpd/conf.d /run/httpd /etc/httpd/logs/

STOPSIGNAL SIGWINCH

USER postgres
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    PGDATA=/var/lib/pgsql/15/data/database \
    JVM_ARGS="-DSPDXParser.OnlyUseLocalLicenses=true -Xmx2048m"

RUN mkdir -p /tmp/extensions && \
    initdb && \
    /usr/local/bin/import_vsix.sh && \
    chmod -R 777 /tmp/extensions && \
    rm -f /var/lib/pgsql/15/data/database/postmaster.pid && \
    rm -f /var/run/postgresql/.s.PGSQL* && \
    rm -f /tmp/.s.PGSQL*

RUN chmod -R g+rwx /var/lib/pgsql /var/lib/pgsql/15 /var/lib/pgsql/data /var/lib/pgsql/backups && \
    chgrp -R 0 /var/lib/pgsql /var/lib/pgsql/15 /var/lib/pgsql/data /var/lib/pgsql/backups && \
    mv /var/lib/pgsql/15/data/database /var/lib/pgsql/15/data/old

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
