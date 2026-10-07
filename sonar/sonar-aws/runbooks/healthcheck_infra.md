# Healthcheck infra

Runs `k8s_status`, `sonar_health`, and `alb_healthcheck` in sequence. Use the runbook button on the install README — there is no cron schedule.

{{ $k8s   := default dict (index (default dict .nuon.actions.workflows) "k8s_status") }}
{{ $sonar := default dict (index (default dict .nuon.actions.workflows) "sonar_health") }}
{{ $alb   := default dict (index (default dict .nuon.actions.workflows) "alb_healthcheck") }}

| Check | Action | Last status |
| --- | --- | --- |
| Kubernetes | `k8s_status` | {{ with dig "status" "" $k8s }}{{ . }}{{ else }}—{{ end }} |
| SonarQube | `sonar_health` | {{ with dig "status" "" $sonar }}{{ . }}{{ else }}—{{ end }} |
| ALB | `alb_healthcheck` | {{ with dig "status" "" $alb }}{{ . }}{{ else }}—{{ end }} |
