#!/usr/bin/env bash
set -euo pipefail

app_dir=$(cd "$(dirname "$0")/.." && pwd)
if [[ -f "$app_dir/.demo.env" ]]; then
  # shellcheck disable=SC1091
  source "$app_dir/.demo.env"
fi

: "${GCP_PROJECT:?Run scripts/1-setup-triggers.sh or set GCP_PROJECT}"

GAR_REGION=${GAR_REGION:-us-west1}
GAR_REPOSITORY=${GAR_REPOSITORY:-nuon-event-proof}
GAR_IMAGE=${GAR_IMAGE:-clickhouse-server}
SOURCE_IMAGE=${SOURCE_IMAGE:-busybox:1.36}
tag=${1:-demo-$(date -u +%Y%m%d%H%M%S)}
full_tag="${GAR_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GAR_REPOSITORY}/${GAR_IMAGE}:${tag}"

gcloud auth configure-docker "${GAR_REGION}-docker.pkg.dev" --quiet >&2
docker pull "$SOURCE_IMAGE" >&2
docker tag "$SOURCE_IMAGE" "$full_tag"
docker push "$full_tag" >&2

echo "$full_tag"
