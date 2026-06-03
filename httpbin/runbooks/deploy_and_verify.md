Deploys the httpbin EC2 instance, then runs verification checks to ensure everything is working correctly.

**Components**

| Component | Description |
|---|---|
| `ec2` | EC2 instance running httpbin |

**Actions**

| Action | Description |
|---|---|
| `healthcheck` | Checks httpbin /status/200 endpoint |
| `instance_status` | Gets EC2 instance details |
| `curl_endpoints` | Tests multiple httpbin endpoints |
