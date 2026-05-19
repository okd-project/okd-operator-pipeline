#!/bin/bash
set -e
pg_ctl -D "${PGDATA}" start
/openvsx-server/run-server.sh &
httpd -D FOREGROUND
