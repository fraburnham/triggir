#!/bin/bash

set -euo pipefail

if [[ -n "$TRIGGIR_DOCKER_IN_DOCKER_PORT" ]] && nc -z -w 1 "$TRIGGIR_DOCKER_IN_DOCKER_SERVICE_HOST" "$TRIGGIR_DOCKER_IN_DOCKER_SERVICE_PORT_DOCKER"; then
    # TRIGGIR_DOCKER_IN_DOCKER_PORT is a bad name it has the full tcp://host:port
    docker context create --docker "host=$TRIGGIR_DOCKER_IN_DOCKER_PORT" k8s-dind
    docker context use k8s-dind
fi

if [[ -d "/setup" ]]; then
    mkdir -p $HOME/.ssh
    cp /setup/.ssh/* $HOME/.ssh/
fi

if [[ -z "${INFLUX_URL:-}" ]] && [[ -n "$TRIGGIR_INFLUXDB_SERVICE_HOST" ]] && [[ -n "$TRIGGIR_INFLUXDB_SERVICE_PORT" ]]; then
    export INFLUX_URL="http://$TRIGGIR_INFLUXDB_SERVICE_HOST:$TRIGGIR_INFLUXDB_SERVICE_PORT/"
fi

# TODO: These variables will break when the release name changes. Make that better. Maybe an init container that runs a command?
# maybe search the env vars and see which ones say POSTGRESQL_SERVICE_HOST
if [[ -z "${DATABASE_URL:-}" ]] && [[ -n "$TRIGGIR_POSTGRESQL_SERVICE_HOST" ]]; then
    export DATABASE_URL="ecto://$PG_USER:$PG_PASS@$TRIGGIR_POSTGRESQL_SERVICE_HOST/$PG_DB"
fi

telegraf -config /etc/telegraf/telegraf.conf &

if command -v tini; then
    exec tini -- "$@"
fi

exec "$@"
