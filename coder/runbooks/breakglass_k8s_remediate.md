Break-glass Kubernetes remediation. These actions run inside the cluster under the break-glass role, so they require break-glass access to be active first.

**Getting break-glass access**

Access is driven entirely by the break-glass role's state on your install stack — there is no separate grant/revoke button:

1. Enable the break-glass role on the install CloudFormation stack (its `Enable…BreakGlass` parameter). Nuon automatically creates an EKS access entry granting the role cluster-admin (`AmazonEKSClusterAdminPolicy`).
2. Run this runbook (or the individual actions) to remediate.
3. Disable the break-glass role on the stack when finished. Nuon automatically removes the access entry, so the role keeps no standing cluster access.

**Remediations**

This runbook runs three actions in one pass:

- `k8s_clean_failed_pods` — deletes `Failed` pods in the `coder` and `coder-observability` namespaces
- `k8s_clear_finalizers` — scans the `coder` namespace for `ingress` resources stuck in `Terminating` and clears their finalizers (or a single resource if `NAME` is set); a safe no-op if nothing is stuck
- `k8s_restart_deployment` — rolling-restarts the deployments in the `coder` namespace (or a single one if `NAME` is set) and waits for rollout

Each can also be run on its own from the Actions list.
