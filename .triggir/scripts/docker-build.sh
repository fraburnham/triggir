#!/bin/bash

set -euo pipefail

docker build -t "$DOCKER_REGISTRY/triggir:$CHECKOUT_SHA" .
docker push "$DOCKER_REGISTRY/triggir:$CHECKOUT_SHA"
