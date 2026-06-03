Deploys all ECS components in order, then runs verification checks to ensure everything is working correctly.

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
