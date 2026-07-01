Runs the three Kubernetes break-glass remediations in one pass:

- `k8s_clean_failed_pods` — deletes `Failed` pods in the `coder` and `coder-observability` namespaces
- `k8s_clear_finalizers` — scans the `coder` namespace for `ingress` resources stuck in `Terminating` and clears their finalizers (or a single resource if `NAME` is set); a safe no-op if nothing is stuck
- `k8s_restart_deployment` — rolling-restarts the deployments in the `coder` namespace (or a single one if `NAME` is set) and waits for rollout

These run under the break-glass role and need cluster access, so run the `breakglass_grant` runbook first. When you are finished, run `breakglass_revoke` to remove access. Each step can also be run on its own from the Actions list.
