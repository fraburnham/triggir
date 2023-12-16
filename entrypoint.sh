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
    chmod 0400 $HOME/.ssh/id_rsa
fi

if [[ -z "${INFLUX_URL:-}" ]] && [[ -n "$TRIGGIR_INFLUXDB_SERVICE_HOST" ]] && [[ -n "$TRIGGIR_INFLUXDB_SERVICE_PORT" ]]; then
    INFLUX_URL="http://$TRIGGIR_INFLUXDB_SERVICE_HOST:$TRIGGIR_INFLUXDB_SERVICE_PORT/"
    export INFLUX_URL
fi

# TODO: These variables will break when the release name changes. Make that better. Maybe an init container that runs a command?
# maybe search the env vars and see which ones say POSTGRESQL_SERVICE_HOST
if [[ -z "${DATABASE_URL:-}" ]] && [[ -n "$TRIGGIR_POSTGRESQL_SERVICE_HOST" ]]; then
    DATABASE_URL="ecto://$POSTGRES_USERNAME:$POSTGRES_PASSWORD@$TRIGGIR_POSTGRESQL_SERVICE_HOST/$POSTGRES_DATABASE"
    export DATABASE_URL
fi

telegraf -config /etc/telegraf/telegraf.conf &

if command -v tini; then
    exec tini -- "$@"
fi

exec "$@"
