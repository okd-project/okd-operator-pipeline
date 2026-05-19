#!/bin/bash
set -e
cd /openvsx-server
java ${JVM_ARGS} \
    -Dspring.config.location=classpath:/application.properties,file:/openvsx-server/config/application.yaml \
    -jar openvsx-server.jar
