Runs verification and status checks for the EKS application without modifying any resources.

**Actions**

| Action | Description |
|---|---|
| `certificate_status` | Checks ACM certificate status |
| `deployments_status` | Gets Kubernetes deployment status |
| `alb` | Gets ALB details (load balancer, upstreams, security groups, ACL) |
| `alb_healthcheck` | Runs ALB health check |
| `whoami` | Tests the whoami endpoint (end-to-end check) |
