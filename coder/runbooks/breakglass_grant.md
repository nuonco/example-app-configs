Opens temporary cluster access for the break-glass role. The break-glass role (`{{ .nuon.install.id }}-coder-sandbox-break-glass`) holds `AdministratorAccess` in AWS but has **no standing access to the EKS cluster** — by default it cannot run kubectl against the workload. This runbook creates an EKS access entry for the role and associates `AmazonEKSClusterAdminPolicy` at cluster scope, so the role can operate inside the cluster until access is revoked.

Access is off by default on purpose: the break-glass role only holds cluster-admin while it is explicitly granted, so a disabled or unused role carries no lingering path into the cluster. Push **Run runbook** to grant access. When you are finished, run the `breakglass_revoke` runbook to remove the access entry.

Granting is idempotent — re-running it when access already exists just re-asserts the policy association and is safe.

**Break-glass workflow**

1. Run this runbook to grant access.
2. Run the Kubernetes break-glass actions below as needed to remediate.
3. Run the `breakglass_revoke` runbook to close access.

**Break-glass actions**

| Action | What it does |
|---|---|
| `break_glass_grant_eks_access`  | Creates the EKS access entry + associates `AmazonEKSClusterAdminPolicy` (this runbook) |
| `k8s_clean_failed_pods`         | Deletes `Failed` pods in the `coder` and `coder-observability` namespaces |
| `k8s_clear_finalizers`          | Clears finalizers on `ingress` resources stuck `Terminating` in `coder` (or a single resource if `NAME` is set) |
| `k8s_restart_deployment`        | Rolling-restarts the `coder`-namespace deployments (or a single one if `NAME` is set) |
| `break_glass_revoke_eks_access` | Deletes the access entry, removing all cluster access (`breakglass_revoke` runbook) |

Each action can also be run on its own from the Actions list; you do not have to run them through a runbook. All of them run under the break-glass role and require access to be granted first.
