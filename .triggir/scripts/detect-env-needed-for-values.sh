#!/bin/bash

set -euo pipefail

function extract_vars() {
    local file="$1"

    grep -E '\$\{.*\}' "$1" \
	| sed -E 's/^.*\$\{(.*)\}.*$/\1/'
}
export -f extract_vars

declare -ag EXPECTED_VARS
EXPECTED_VARS=(
    $(find helm/triggir/ \( -path 'helm/triggir/*values.yaml' -not -path 'helm/triggir/charts/*' \) \
	  | xargs -n1 bash -c 'extract_vars $1' -- \
	  | sort \
	  | uniq)
)

if [[ -n "$CHECKOUT_SHA" ]]; then
    IMAGE_TAG="$CHECKOUT_SHA"
fi

IMAGE_TAG="${IMAGE_TAG:-latest}"


MISSING=false
for var in "${EXPECTED_VARS[@]}"; do
    set +u
    [[ -n "${!var}" ]] || { echo "Missing: '$var'"; MISSING=true; }
    set -u
done

$MISSING && exit 1
