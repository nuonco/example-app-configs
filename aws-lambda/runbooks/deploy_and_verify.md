Deploys all Lambda app components in order, then runs verification actions to check status, invoke the function, and retrieve logs.

**Components**

| Component | Description |
|---|---|
| `lambda_function` | Lambda function |
| `certificate` | SSL certificate |
| `api_gateway` | API Gateway |

**Actions**

| Action | Description |
|---|---|
| `lambda_status` | Gets Lambda function configuration |
| `invoke_lambda` | Invokes the Lambda function |
| `lambda_logs` | Retrieves recent CloudWatch logs |
