#!/usr/bin/env bash
set -euo pipefail

for command in gcloud jq nuon; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

: "${GCP_PROJECT:?Set GCP_PROJECT to the GAR project ID}"

GAR_REGION=${GAR_REGION:-us-west1}
GAR_REPOSITORY=${GAR_REPOSITORY:-nuon-event-proof}
GAR_IMAGE=${GAR_IMAGE:-clickhouse-server}
GAR_TRIGGER_NAME=${GAR_TRIGGER_NAME:-gar-tag-proof-pubsub-v2}
APPROVAL_TRIGGER_NAME=${APPROVAL_TRIGGER_NAME:-release-approval-http}
BRANCH_TRIGGER_NAME=${BRANCH_TRIGGER_NAME:-app-branch-run-http}
PUBSUB_TOPIC=${PUBSUB_TOPIC:-gcr}
PUBSUB_SUBSCRIPTION=${PUBSUB_SUBSCRIPTION:-nuon-gar-tag-proof}
PUBSUB_PUSH_SERVICE_ACCOUNT=${PUBSUB_PUSH_SERVICE_ACCOUNT:-nuon-event-push@${GCP_PROJECT}.iam.gserviceaccount.com}
PUBSUB_AUDIENCE=${PUBSUB_AUDIENCE:-https://nuon.co/triggers/${GAR_TRIGGER_NAME}}

project_number=$(gcloud projects describe "$GCP_PROJECT" --format='value(projectNumber)')
push_service_account_name=${PUBSUB_PUSH_SERVICE_ACCOUNT%@*}

gcloud artifacts repositories describe "$GAR_REPOSITORY" \
  --project "$GCP_PROJECT" \
  --location "$GAR_REGION" >/dev/null 2>&1 || \
  gcloud artifacts repositories create "$GAR_REPOSITORY" \
    --project "$GCP_PROJECT" \
    --location "$GAR_REGION" \
    --repository-format docker

gcloud pubsub topics describe "$PUBSUB_TOPIC" --project "$GCP_PROJECT" >/dev/null 2>&1 || \
  gcloud pubsub topics create "$PUBSUB_TOPIC" --project "$GCP_PROJECT"

gcloud pubsub topics add-iam-policy-binding "$PUBSUB_TOPIC" \
  --project "$GCP_PROJECT" \
  --member "serviceAccount:service-${project_number}@gcp-sa-artifactregistry.iam.gserviceaccount.com" \
  --role roles/pubsub.publisher >/dev/null

gcloud iam service-accounts describe "$PUBSUB_PUSH_SERVICE_ACCOUNT" \
  --project "$GCP_PROJECT" >/dev/null 2>&1 || \
  gcloud iam service-accounts create "$push_service_account_name" \
    --project "$GCP_PROJECT" \
    --display-name "Nuon event push"

gcloud iam service-accounts add-iam-policy-binding "$PUBSUB_PUSH_SERVICE_ACCOUNT" \
  --project "$GCP_PROJECT" \
  --member "serviceAccount:service-${project_number}@gcp-sa-pubsub.iam.gserviceaccount.com" \
  --role roles/iam.serviceAccountTokenCreator >/dev/null

gar_trigger=$(nuon triggers create "$GAR_TRIGGER_NAME" \
  --preset google-pubsub \
  --audience "$PUBSUB_AUDIENCE" \
  --expected-email "$PUBSUB_PUSH_SERVICE_ACCOUNT" \
  --output json)

gar_trigger_id=$(jq -r '.trigger.id' <<<"$gar_trigger")
gar_ingress_url=$(jq -r '.ingress_url' <<<"$gar_trigger")

gcloud pubsub subscriptions create "$PUBSUB_SUBSCRIPTION" \
  --project "$GCP_PROJECT" \
  --topic "$PUBSUB_TOPIC" \
  --push-endpoint "$gar_ingress_url" \
  --push-auth-service-account "$PUBSUB_PUSH_SERVICE_ACCOUNT" \
  --push-auth-token-audience "$PUBSUB_AUDIENCE"

approval_trigger=$(nuon triggers create "$APPROVAL_TRIGGER_NAME" \
  --auth-type api_key \
  --type-header X-Nuon-Event-Type \
  --id-header X-Nuon-Event-ID \
  --output json)

approval_trigger_id=$(jq -r '.trigger.id' <<<"$approval_trigger")
approval_ingress_url=$(jq -r '.ingress_url' <<<"$approval_trigger")
approval_secret=$(jq -r '.secret' <<<"$approval_trigger")

branch_trigger=$(nuon triggers create "$BRANCH_TRIGGER_NAME" \
  --auth-type api_key \
  --type-header X-Nuon-Event-Type \
  --id-header X-Nuon-Event-ID \
  --output json)

branch_trigger_id=$(jq -r '.trigger.id' <<<"$branch_trigger")
branch_ingress_url=$(jq -r '.ingress_url' <<<"$branch_trigger")
branch_secret=$(jq -r '.secret' <<<"$branch_trigger")

env_file=$(cd "$(dirname "$0")/.." && pwd)/.demo.env
{
  printf 'GCP_PROJECT=%q\n' "$GCP_PROJECT"
  printf 'GAR_REGION=%q\n' "$GAR_REGION"
  printf 'GAR_REPOSITORY=%q\n' "$GAR_REPOSITORY"
  printf 'GAR_IMAGE=%q\n' "$GAR_IMAGE"
  printf 'GAR_TRIGGER_ID=%q\n' "$gar_trigger_id"
  printf 'APPROVAL_TRIGGER_ID=%q\n' "$approval_trigger_id"
  printf 'APPROVAL_INGRESS_URL=%q\n' "$approval_ingress_url"
  printf 'APPROVAL_TRIGGER_SECRET=%q\n' "$approval_secret"
  printf 'BRANCH_TRIGGER_ID=%q\n' "$branch_trigger_id"
  printf 'BRANCH_INGRESS_URL=%q\n' "$branch_ingress_url"
  printf 'BRANCH_TRIGGER_SECRET=%q\n' "$branch_secret"
} > "$env_file"
chmod 600 "$env_file"

echo "Created all three Triggers and the Pub/Sub push subscription."
echo "Saved test credentials to $env_file."
