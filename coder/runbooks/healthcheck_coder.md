Refreshes every Coder data table on the install README in one shot — deployment health matrix, agent connectivity, template freshness, provisioner status, workspaces, users, templates, builds, and the job queue. Mix of `psql` queries against the Coder Postgres database via the `coder-db-url` secret and unauthenticated calls to public Coder endpoints (`/api/v2/buildinfo`, `/derp/latency-check`). No Coder API token required.

Use this after creating new workspaces, deploying templates, registering provisioner daemons, or whenever the install dashboard tables look stale.

**Actions**

| Action | Populates |
|---|---|
| `coder_deployment_health`  | 6-subsystem health matrix (access url, database, provisioner daemons, derp, websocket, workspace proxy) |
| `coder_agents_health`      | Running workspaces with disconnected agents (warn banner only if count > 0) |
| `coder_template_freshness` | Templates not updated in 90+ days |
| `coder_provisioners`       | Provisioners table — name, last-seen status (green if <60s), version |
| `coder_workspaces`         | Workspace counts by status + recently active workspaces |
| `coder_users_templates`    | User counts (total, active, dormant, suspended) + templates with workspace counts |
| `coder_builds_jobs`        | Last 10 workspace builds + provisioner job queue (last hour) |
