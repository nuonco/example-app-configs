#!/usr/bin/env bash

set -e
set -o pipefail
set -u

kubectl events --types=Warning,Normal
kubectl events --types=Warning,Normal -o json | jq -c >> $NUON_ACTIONS_OUTPUT_FILEPATH
