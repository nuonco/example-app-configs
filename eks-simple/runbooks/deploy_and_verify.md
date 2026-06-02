Deploys all EKS components in order, then runs verification checks to ensure everything is working correctly.

**Components**

| Component | Description |
|---|---|
| `certificate` | ACM certificate for domain |
| `whoami` | Whoami Helm chart deployment |
| `application_load_balancer` | Application Load Balancer |

**Actions**

| Action | Description |
|---|---|
| `certificate_status` | Checks ACM certificate status |
| `deployments_status` | Gets Kubernetes deployment status |
| `alb` | Gets ALB details (load balancer, upstreams, security groups, ACL) |
| `alb_healthcheck` | Runs ALB health check |
| `whoami` | Tests the whoami endpoint (end-to-end check) |
