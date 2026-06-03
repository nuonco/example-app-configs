Deploys all ECS components, verifies everything is working, then forces a service restart with zero downtime.

**Components**

| Component | Description |
|---|---|
| `img_whoami` | Container image |
| `cluster` | ECS cluster |
| `certificate` | ACM certificate |
| `whoami` | ECS service |
| `alb` | Application Load Balancer |

**Actions**

| Action | Description |
|---|---|
| `service_status` | Gets ECS service status and deployment details |
| `certificate_status` | Checks ACM certificate status |
| `curl_endpoint` | Tests the service endpoint (end-to-end check) |
| `restart_service` | Forces a new deployment (rolling restart) |
