#!/usr/bin/env sh

set -e
set -o pipefail
set -u

kubectl get --all-namespaces deployments
