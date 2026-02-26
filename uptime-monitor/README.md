# Uptime Monitor

**Warning:** This application is for demonstration purposes only and is not intended for production use. The admin panel allows triggering AWS infrastructure changes directly from the application.

A demo application that monitors website uptime. Enter a URL and the system periodically checks if it's up, storing results in PostgreSQL and displaying them as a real-time bar graph.

**Your Instance:** [{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}](http://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

## Headlamp Dashboard

Access the Kubernetes dashboard to view pods, deployments, and cluster resources.

**Headlamp:** [ {{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}/headlamp](http://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/headlamp/)

**Authentication Token:**
```
{{ .nuon.actions.workflows.headlamp_token.outputs.steps.create.token }}
```

## Creating Drift

This demo app is configured to detect drift across Terraform, Kubernetes, and Helm components. You can intentionally create drift to see how Nuon detects and displays it in the dashboard.

### Terraform Drift (RDS)

The app includes an admin panel that modifies RDS settings outside of Terraform.

1. Go to [ {{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}/admin](http://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/admin)
2. Click the button to modify the RDS instance (changes max allocated storage and tags)
3. In the Nuon dashboard, trigger a drift scan on the `rds` component
4. Nuon will detect the configuration has drifted from the Terraform state

### Kubernetes Manifest Drift (API/UI)

Modify deployments directly in Kubernetes to create drift from the declared manifests.

1. Open [Headlamp](http://{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}/headlamp/) and login with the token above
2. Navigate to **Workloads > Deployments**
3. Select the `api` or `ui` deployment
4. Click **Edit** and change the replica count (e.g., from 1 to 2)
5. Save the changes
6. In the Nuon dashboard, trigger a drift scan on the `api` or `ui` component
7. Nuon will detect the replica count differs from the manifest

### Helm Drift (Headlamp)

Modify Helm-managed resources to create drift from the chart values.

1. Open [Headlamp](http://{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}/headlamp/) and login with the token above
2. Navigate to **Workloads > Deployments**
3. Select the `headlamp` deployment
4. Click **Edit** and modify a value (e.g., change replica count or resource limits)
5. Save the changes
6. In the Nuon dashboard, trigger a drift scan on the `headlamp` component
7. Nuon will detect the deployed resources differ from the Helm release

## Full State

<details>
  <summary>Full Install State</summary>
  <pre>{{ toPrettyJson .nuon }}</pre>
</details>
