# Sync workflows

`sync-all-apps.yaml` syncs app configs to a Nuon API using a per-environment
[GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
secret named `NUON_CONFIG`.

- `sync-all-apps.yaml` is dispatched manually and lets you pick the environment,
  ref, and an optional subset of apps. Syncing never happens automatically on
  PRs or pushes.

The job selects a GitHub Environment and reads `secrets.NUON_CONFIG` from it,
writing the value to `$HOME/.nuon` before running `nuon apps sync`.

## Adding a new environment

The `NUON_CONFIG` secret is the full `~/.nuon` YAML config, and its `api_token`
**must be an org-admin token minted from the environment's admin API** — a normal
`nuon auth login` user token is not sufficient for syncing apps org-wide.

1. Reach the environment's admin API. It is internal, so port-forward it (example
   for stage; swap `stage` for the target environment):

   ```sh
   kubectl --context <env-cluster> -n ctl-api \
     port-forward svc/ctl-api-<env>-admin 8082:80
   ```

2. Ensure the org admin service account exists, then mint a long-lived token
   (admin calls are authorized by the `X-Nuon-Admin-Email` header):

   ```sh
   ADMIN_API_URL="http://localhost:8082"
   ORG_ID="org_xxxxxxxxxxxxxxxxxxxxxxxx"
   ADMIN_EMAIL="you@nuon.co"

   curl -sS -X POST "${ADMIN_API_URL}/v1/orgs/${ORG_ID}/admin-service-account" \
     -H "Content-Type: application/json" \
     -H "X-Nuon-Admin-Email: ${ADMIN_EMAIL}" \
     -d '{}'

   curl -sS -X POST "${ADMIN_API_URL}/v1/general/admin-static-token" \
     -H "Content-Type: application/json" \
     -H "X-Nuon-Admin-Email: ${ADMIN_EMAIL}" \
     -d "{\"email_or_subject\": \"${ORG_ID}-admin-service-account\", \"duration\": \"8760h\"}"
   ```

   The second call returns `{"api_token": "..."}`.

3. Assemble the `~/.nuon` config for the environment:

   ```yaml
   api_url: https://api.<env>.nuon.co
   org_id: org_xxxxxxxxxxxxxxxxxxxxxxxx
   api_token: <api_token from step 2>
   ```

4. Create the GitHub Environment (repo **Settings → Environments → New
   environment**), naming it to match the value used in the workflows (e.g.
   `stage`, `prod`).

5. Add the `NUON_CONFIG` secret to that environment:

   ```sh
   gh secret set NUON_CONFIG --env <environment-name> < ~/.nuon
   ```

   Verify with:

   ```sh
   gh secret list --env <environment-name>
   ```

6. To make it selectable in `sync-all-apps.yaml`, add the environment name to the
   `environment` input `options` list.

Because the secret carries `api_url`, `org_id`, and the admin `api_token`, each
environment is fully scoped by its own `NUON_CONFIG` — no other workflow changes
are needed to point an environment at a different API.
