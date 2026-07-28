# Event automation: GAR release approval

This example demonstrates a complete external-event runbook:

1. A Docker image is pushed to Google Artifact Registry (GAR).
2. Artifact Registry publishes an `INSERT` notification to the `gcr` Pub/Sub topic.
3. A Google Pub/Sub Trigger receives the event and starts `gar-release-approval-deploy`.
4. The runbook validates the image tag and pauses at a `wait_for_event` step.
5. An authenticated HTTP Trigger receives a matching `release.approved` event.
6. The runbook resumes, reads the approval payload, and records the approved image in the install's `default` Kubernetes namespace.

## Prerequisites

- A Nuon environment containing the Trigger and `wait_for_event` changes.
- The matching Nuon CLI build, authenticated to the intended organization.
- An existing app install with a healthy Kubernetes runner.
- `gcloud`, `docker`, `jq`, and `nuon` on your PATH.
- Access to a GCP project where you can manage Artifact Registry, Pub/Sub, and service accounts.

The defaults use the original proof environment:

```text
project:    nuon-gcp-support
region:     us-west1
repository: nuon-event-proof
image:      clickhouse-server
```

Set the variables accepted by `scripts/1-setup-triggers.sh` if you use a different project or repository. If the GAR image path changes, also update the prefix filter in `events.toml` and the allowlist in `src/1-validate-trigger-tag.sh`.

## Configure the app

Set the target install name in `events.toml`:

```toml
[rules.target]
type = "runbook"
runbook = "gar-release-approval-deploy"
install = "your-install-name"
```

The app and install must already exist before syncing the event rule because Nuon resolves the target install during app config sync. For a new app, sync and create the install first with `events.toml` temporarily omitted, then restore the file and sync again.

From this directory, select the intended app and sync:

```bash
nuon apps select
nuon apps sync .
```

## Create the Triggers

The setup script creates:

- `gar-tag-proof-pubsub-v2`: Google Pub/Sub with Google-signed OIDC authentication.
- `release-approval-http`: generic HTTP with API-key authentication.
- The GAR repository and `gcr` topic if they do not exist.
- A push-auth service account and Pub/Sub push subscription.

Run it with your GCP project:

```bash
export GCP_PROJECT=nuon-gcp-support
./scripts/1-setup-triggers.sh
```

The script writes the HTTP Trigger URL and API key to `.demo.env`, which is ignored by Git and mode `0600`. Trigger secrets are only shown when created or explicitly revealed; do not share or commit this file.

If either Trigger already exists, delete it first or set `GAR_TRIGGER_NAME` and `APPROVAL_TRIGGER_NAME` and update the matching names in `events.toml` and the runbook.

## Run the demo

Push a small image to GAR and capture the full tag:

```bash
full_tag=$(./scripts/2-push-gar-image.sh)
echo "$full_tag"
```

Artifact Registry notifications are asynchronous. Open the `gar-tag-proof-pubsub-v2` Trigger's Events tab until the `INSERT` event starts the runbook. You can also confirm that the Trigger has received an event from the CLI:

```bash
nuon triggers list
```

Open the runbook in Nuon and confirm it is paused at `wait-for-release-approval`. Send the matching approval event:

```bash
./scripts/3-approve-release.sh "$full_tag" colleague@example.com
```

The runbook should resume and finish. Its final step creates or updates this ConfigMap:

```bash
kubectl --kubeconfig /path/to/install-kubeconfig \
  get configmap nuon-event-image-tag \
  --namespace default \
  -o jsonpath='{.data.image}'
```

The value should equal the GAR tag printed by `2-push-gar-image.sh`.

## Files

- `events.toml` routes matching GAR events into the runbook and maps `$.tag` to `image_tag`.
- `runbooks/gar-release-approval-deploy.toml` defines the action, wait, validation, and recording steps.
- `src/` contains the scripts executed by the runbook.
- `scripts/` contains the operator-side setup, image push, and approval commands.
