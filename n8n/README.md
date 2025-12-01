{{ $region := .nuon.install_stack.outputs.region }}

<p align="center">
  <img src="https://community.n8n.io/uploads/default/original/3X/a/c/ac84cdc62ae7091365a95961177e16eb61b12b6e.gif" alt="n8n Workflow Automation" width="100%"/>
</p>

<h1 align="center">n8n with AI - Workflow Automation Platform</h1>

<p align="center">
  <a href="https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}">
    <img src="deploy-button.svg" alt="Deploy in your Cloud" width="189" height="40" />
  </a>
</p>

<p align="center">
  <strong>Open-source workflow automation with integrated Ollama AI</strong><br/>
  Deploy n8n in your own AWS account with local AI inference capabilities
</p>

<div align="center" style="background: linear-gradient(135deg, #8040BF 0%, #a060df 100%); padding: 20px; border-radius: 10px; margin: 20px 0;">
  <p style="color: white; font-size: 16px; margin: 0;">
    <strong>✅ Deployed and Running</strong>
  </p>
  <p style="color: #f0e6ff; font-size: 14px; margin: 10px 0 0 0;">
    {{ if .nuon.install_stack.outputs }}
    AWS Account: {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | Region: {{ $region }} | VPC: {{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}
    {{ else }}
    AWS Account: 000000000000 | Region: xx-xxxx-00 | VPC: vpc-000000
    {{ end }}
  </p>
</div>

---

## 📋 Table of Contents

- [Quick Access](#-quick-access)
- [What is n8n?](#-what-is-n8n)
- [Architecture Overview](#-architecture-overview)
- [How the App Operates](#-how-the-app-operates)
- [Operational Runbook](#-operational-runbook)
- [Day-2 Operations](#-day-2-operations)
- [Troubleshooting](#-troubleshooting)
- [Use Cases](#-use-cases)
- [Resources](#-resources)

---

## 🌐 Quick Access

### Access URLs

**n8n Interface:** [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

**Webhook Base URL:**
```
https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/webhook/
```

**API Endpoint:**
```
https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/api/v1/
```

### 🔑 Default Credentials

```
Username: admin
Password: n8n-2024!
```

⚠️ **Important:** Change this password immediately after first login!

---

## 🤖 What is n8n?

n8n is a **fair-code licensed workflow automation platform** that enables you to connect apps and automate workflows. Think of it as a self-hosted alternative to Zapier or Make.com, but with:

- **350+ integrations** with popular services (Slack, Gmail, Salesforce, databases, APIs)
- **Visual workflow builder** with drag-and-drop interface
- **Code execution** (JavaScript/Python) for custom logic
- **AI/LLM capabilities** for intelligent automation
- **Webhook support** for real-time triggers
- **100% data sovereignty** - everything runs in your infrastructure

### Why This Deployment?

This Nuon app configuration deploys n8n with:

✅ **Built-in AI** - Integrated Ollama server for local AI inference (no API costs!)  
✅ **Production-ready** - Queue-based execution with Redis and PostgreSQL  
✅ **Scalable** - Auto-scaling workers for parallel workflow processing  
✅ **Secure** - SSL/TLS, isolated VPC, encrypted storage  
✅ **Observable** - CloudWatch logs, metrics, and health checks  
✅ **Automated backups** - Daily database backups with retention policies

---

## 🏗️ Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Internet (HTTPS)                     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              AWS Application Load Balancer              │
│          (TLS Termination + Health Checks)              │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    EKS Cluster (n8n namespace)          │
│                                                          │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   n8n Main   │────────▶│  PostgreSQL  │             │
│  │  (Web UI +   │         │  (Workflows, │             │
│  │   API)       │         │  Credentials)│             │
│  └──────┬───────┘         └──────────────┘             │
│         │                                                │
│         │                 ┌──────────────┐             │
│         └────────────────▶│    Redis     │◀────┐       │
│                           │  (Queue +    │     │       │
│                           │   Cache)     │     │       │
│                           └──────────────┘     │       │
│                                                 │       │
│  ┌──────────────┐                             │       │
│  │ n8n Workers  │─────────────────────────────┘       │
│  │ (Background  │                                      │
│  │  Execution)  │         ┌──────────────┐            │
│  └──────┬───────┘         │    Ollama    │            │
│         │                 │  AI Server   │            │
│         └────────────────▶│  (Local LLM) │            │
│                           └──────────────┘            │
│                                                        │
└────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              S3 Buckets (Backups & Files)               │
└─────────────────────────────────────────────────────────┘
```

### Component Details

| Component | Purpose | Replicas | Storage |
|-----------|---------|----------|---------|
| **n8n Main** | Web interface, API server, workflow editor | 1 | {{ .nuon.inputs.inputs.workflow_storage_gb }}GB (PVC) |
| **n8n Workers** | Background workflow execution (queue mode) | {{ .nuon.inputs.inputs.worker_replicas }} | Shared with main |
| **PostgreSQL** | Persistent data (workflows, credentials, executions) | 1 | {{ .nuon.inputs.inputs.db_storage_gb }}GB (PVC) |
| **Redis** | Message queue + cache for distributed execution | 1 | {{ .nuon.inputs.inputs.redis_storage_gb }}GB (PVC) |
| **Ollama Server** | Local AI model inference ({{ .nuon.inputs.inputs.ollama_model }}) | 1 | {{ .nuon.inputs.inputs.ollama_storage_gb }}GB (PVC) |
| **ALB Ingress** | HTTPS load balancer with TLS termination | N/A | N/A |
| **S3 Buckets** | Automated backups and file storage | N/A | Unlimited |

---

## ⚙️ How the App Operates

### Deployment Flow

1. **Infrastructure Provisioning**
   - Nuon creates VPC, subnets, and EKS cluster in your AWS account
   - IAM roles and service accounts are configured with least-privilege access
   - Storage classes and persistent volumes are provisioned

2. **Component Deployment Order**
   ```
   S3 Buckets → Certificate → PostgreSQL → Redis → Ollama → n8n Main → Workers → Ingress
   ```
   - Dependencies ensure services start in the correct order
   - Health checks validate each component before proceeding

3. **Post-Deployment Configuration**
   - AI model is automatically downloaded (triggered by `pull_ollama_model` action)
   - DNS records are configured for the domain
   - TLS certificates are provisioned and attached to ALB
   - Health checks verify all components are operational

### Workflow Execution Model

n8n operates in **queue mode** for production reliability:

```
User Triggers Workflow
        ↓
n8n Main (receives request)
        ↓
Adds job to Redis Queue
        ↓
n8n Worker (picks up job)
        ↓
Executes workflow steps
        ↓
Stores results in PostgreSQL
        ↓
Returns status to user
```

**Benefits of Queue Mode:**
- **Reliability**: Jobs persist in Redis even if workers restart
- **Scalability**: Add more workers to process jobs in parallel
- **Isolation**: Main app remains responsive during heavy workloads
- **Retry logic**: Failed jobs can be automatically retried

### AI Integration

The Ollama server provides **local AI inference** without external API calls:

**Internal Endpoint:**
```
http://ollama-server.n8n.svc.cluster.local:11434
```

**Example HTTP Request Node Configuration:**
```json
{
  "url": "http://ollama-server.n8n.svc.cluster.local:11434/api/generate",
  "method": "POST",
  "body": {
    "model": "{{ .nuon.inputs.inputs.ollama_model }}",
    "prompt": "Your prompt here",
    "stream": false
  }
}
```

**Security:** Ollama is NOT exposed externally - only accessible within the Kubernetes cluster.

---

## 📖 Operational Runbook

### Initial Setup

#### 1. First Login

1. Navigate to: `https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}`
2. Log in with default credentials (see above)
3. **Immediately change password** in Settings → Users & Security
4. Configure your profile and notification preferences

#### 2. Verify AI Model

Run the `pull_ollama_model` action to ensure the AI model is downloaded:

```bash
# Via Nuon CLI
nuon installs actions run --install-id {{ .nuon.install.id }} --action pull_ollama_model

# Or via Nuon Dashboard
# Navigate to: Installs → Actions → "Pull Ollama Model" → Run
```

Expected output:
```
✅ Successfully downloaded tinyllama:1.1b
🎯 Ollama endpoint: http://ollama-server.n8n.svc.cluster.local:11434
```

#### 3. Create Your First Workflow

1. Click **"New Workflow"** in the n8n interface
2. Add a **Manual Trigger** node
3. Add an **HTTP Request** node:
   - URL: `http://ollama-server.n8n.svc.cluster.local:11434/api/generate`
   - Method: POST
   - Body: `{"model": "tinyllama", "prompt": "Hello, AI!", "stream": false}`
4. Click **"Execute Workflow"** to test
5. Save your workflow

### Health Monitoring

#### Run Health Check

The `health_check` action verifies all components:

```bash
nuon installs actions run --install-id {{ .nuon.install.id }} --action health_check
```

**What it checks:**
- ✅ PostgreSQL database status and connectivity
- ✅ Redis queue status and statistics
- ✅ n8n main application health
- ✅ Worker count and status
- ✅ Ingress/ALB configuration
- ✅ Persistent volume claims
- ✅ External URL accessibility

**Expected output:**
```
========================================
Health Check Summary
========================================
Pods: 7/7 running
✅ All systems operational

Access URLs:
n8n Interface: https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
Webhook Base: https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/webhook/
API Endpoint: https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/api/v1/
```

#### Manual Health Checks

Access the EKS cluster directly:

```bash
# Get all pods in n8n namespace
kubectl get pods -n n8n

# Check specific component logs
kubectl logs -n n8n -l app=n8n-main --tail=50
kubectl logs -n n8n -l app=n8n-worker --tail=50
kubectl logs -n n8n -l app=ollama --tail=50

# Check persistent volumes
kubectl get pvc -n n8n

# Check services and ingress
kubectl get svc,ingress -n n8n
```

---

## 🔧 Day-2 Operations

### Scaling Operations

#### Scale Workers

Adjust worker replicas based on workload:

```bash
# Via Nuon action
nuon installs actions run --install-id {{ .nuon.install.id }} \
  --action scale_workers \
  --input worker_count=5

# Or via kubectl
kubectl scale deployment/n8n-workers -n n8n --replicas=5
```

**When to scale:**
- **Scale up** if workflows are queuing or execution times increase
- **Scale down** during low-traffic periods to reduce costs

**Monitoring queue depth:**
```bash
nuon installs actions run --install-id {{ .nuon.install.id }} --action view_queue_stats
```

#### Vertical Scaling

To increase resources per component, update the Helm values and redeploy:

```yaml
# components/values/n8n/n8n.yaml
resources:
  requests:
    memory: "1Gi"    # Increase from 512Mi
    cpu: "1000m"     # Increase from 500m
  limits:
    memory: "4Gi"    # Increase from 2Gi
    cpu: "3000m"     # Increase from 2000m
```

### Backup Operations

#### Manual Backup

```bash
nuon installs actions run --install-id {{ .nuon.install.id }} --action backup_workflows
```

This creates a PostgreSQL dump and uploads it to S3 (if enabled).

#### Automated Backups

Backups run automatically **daily at 2 AM** via cron trigger.

**Configuration:**
- Retention: `{{ .nuon.inputs.inputs.db_backup_retention_days }}` days
- Location: S3 bucket `{{ .nuon.install.id }}-n8n-backups/`

#### Restore from Backup

```bash
# List available backups
aws s3 ls s3://{{ .nuon.install.id }}-n8n-backups/

# Download backup
aws s3 cp s3://{{ .nuon.install.id }}-n8n-backups/n8n_backup_20240115_020000.sql /tmp/

# Get PostgreSQL pod
PG_POD=$(kubectl get pods -n n8n -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')

# Restore database
cat /tmp/n8n_backup_20240115_020000.sql | kubectl exec -i -n n8n $PG_POD -- psql -U n8n -d n8n
```

### Maintenance Operations

#### Restart Services

```bash
nuon installs actions run --install-id {{ .nuon.install.id }} --action restart_services
```

Or restart individual components:

```bash
# Restart n8n main
kubectl rollout restart deployment/n8n-main -n n8n

# Restart workers
kubectl rollout restart deployment/n8n-workers -n n8n

# Restart Ollama
kubectl rollout restart deployment/ollama-server -n n8n
```

#### Clear Old Execution Data

To free up database space:

```bash
nuon installs actions run --install-id {{ .nuon.install.id }} --action clear_execution_data
```

This removes execution history older than `{{ .nuon.inputs.inputs.executions_data_max_age }}` hours.

#### Install Community Nodes

```bash
nuon installs actions run --install-id {{ .nuon.install.id }} \
  --action install_community_node \
  --input node_name="n8n-nodes-telegram"
```

#### Change AI Model

```bash
# Update the model in inputs.toml or via Nuon dashboard
# Then pull the new model
nuon installs actions run --install-id {{ .nuon.install.id }} --action pull_ollama_model
```

**Available models:**
- `tinyllama` (1.1B params) - Fast, minimal resources
- `llama3.2:1b` (1B params) - Good balance
- `llama3.2:3b` (3B params) - Better quality
- `mistral` (7B params) - Production quality
- `codellama` (7B params) - Code generation

### Monitoring & Observability

#### CloudWatch Logs

View logs in AWS Console:

```
Log Groups:
- /aws/eks/{{ .nuon.install.id }}/n8n-main
- /aws/eks/{{ .nuon.install.id }}/n8n-workers
- /aws/eks/{{ .nuon.install.id }}/postgresql
- /aws/eks/{{ .nuon.install.id }}/redis
- /aws/eks/{{ .nuon.install.id }}/ollama
```

#### Metrics

n8n exposes Prometheus metrics at:
```
http://n8n-main.n8n.svc.cluster.local:5678/metrics
```

**Key metrics:**
- `n8n_workflow_executions_total` - Total workflow executions
- `n8n_workflow_execution_duration_seconds` - Execution duration
- `n8n_workflow_execution_errors_total` - Failed executions
- `n8n_queue_jobs_waiting` - Jobs in queue

#### View Queue Statistics

```bash
nuon installs actions run --install-id {{ .nuon.install.id }} --action view_queue_stats
```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Workflows Not Executing

**Symptoms:** Workflows stuck in "waiting" state

**Diagnosis:**
```bash
# Check worker status
kubectl get pods -n n8n -l app=n8n-worker

# Check Redis connectivity
kubectl exec -n n8n -l app=redis -- redis-cli ping
```

**Solutions:**
- Scale up workers if queue is backed up
- Restart workers: `kubectl rollout restart deployment/n8n-workers -n n8n`
- Check Redis logs for connection issues

#### 2. AI Nodes Failing

**Symptoms:** HTTP Request to Ollama returns errors

**Diagnosis:**
```bash
# Check Ollama pod status
kubectl get pods -n n8n -l app=ollama

# Check Ollama logs
kubectl logs -n n8n -l app=ollama --tail=50

# Verify model is loaded
kubectl exec -n n8n -l app=ollama -- ollama list
```

**Solutions:**
- Pull model: Run `pull_ollama_model` action
- Restart Ollama: `kubectl rollout restart deployment/ollama-server -n n8n`
- Check storage: `kubectl get pvc -n n8n | grep ollama`

#### 3. Database Connection Errors

**Symptoms:** n8n shows "Database connection failed"

**Diagnosis:**
```bash
# Check PostgreSQL pod
kubectl get pods -n n8n -l app.kubernetes.io/name=postgresql

# Check PostgreSQL logs
kubectl logs -n n8n -l app.kubernetes.io/name=postgresql --tail=50

# Test connection from n8n pod
kubectl exec -n n8n -l app=n8n-main -- nc -zv postgres-postgresql 5432
```

**Solutions:**
- Restart PostgreSQL: `kubectl rollout restart statefulset/postgres-postgresql -n n8n`
- Check PVC: `kubectl get pvc -n n8n | grep postgres`
- Verify credentials in secrets

#### 4. Cannot Access n8n URL

**Symptoms:** Browser shows "Site can't be reached"

**Diagnosis:**
```bash
# Check ingress
kubectl get ingress -n n8n

# Check ALB status in AWS Console
# Check DNS records in Route 53

# Test internal connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -I http://n8n-main.n8n.svc.cluster.local:5678
```

**Solutions:**
- Wait for DNS propagation (can take 5-10 minutes)
- Verify certificate is attached to ALB
- Check security groups allow HTTPS (443)

#### 5. High Memory Usage

**Symptoms:** Pods being OOMKilled or restarting frequently

**Diagnosis:**
```bash
# Check resource usage
kubectl top pods -n n8n

# Check pod events
kubectl describe pod -n n8n <pod-name>
```

**Solutions:**
- Increase resource limits in Helm values
- Scale horizontally (add more workers)
- Enable execution data pruning
- Clear old execution data

### Getting Help

**Logs to collect:**
```bash
# Export all logs
kubectl logs -n n8n -l app=n8n-main --tail=500 > n8n-main.log
kubectl logs -n n8n -l app=n8n-worker --tail=500 > n8n-workers.log
kubectl logs -n n8n -l app=ollama --tail=100 > ollama.log

# Export pod status
kubectl get pods -n n8n -o yaml > pods-status.yaml

# Export events
kubectl get events -n n8n --sort-by='.lastTimestamp' > events.log
```

**Support Channels:**
- Nuon Support: support@nuon.co
- n8n Community: https://community.n8n.io
- GitHub Issues: https://github.com/nuonco/example-app-configs/issues

---

## 💡 Use Cases

### 1. AI-Powered Customer Support

**Workflow:**
```
Webhook (New Ticket) → Extract Ticket Data → Send to Ollama AI → 
Analyze Sentiment → Route to Team → Generate Draft Response → 
Update Ticket System → Notify Team
```

**Benefits:**
- Automatic ticket triage and prioritization
- AI-generated response suggestions
- Sentiment analysis for escalation
- 100% private - no data leaves your infrastructure

### 2. Data Pipeline Automation

**Workflow:**
```
Schedule (Hourly) → Fetch from Multiple APIs → Transform Data → 
Validate → Store in Database → Generate Report → 
Email Summary to Team
```

**Benefits:**
- Automated data collection and processing
- Error handling and retry logic
- Scheduled execution with queue reliability
- Scalable with worker replicas

### 3. E-commerce Order Processing

**Workflow:**
```
Webhook (New Order) → Validate Payment → Add to CRM → 
Send Slack Notification → Create Fulfillment Task → 
Update Inventory → Send Confirmation Email
```

**Benefits:**
- Real-time order processing
- Multi-system integration
- Reliable execution with queue mode
- Audit trail in execution history

### 4. Content Generation Pipeline

**Workflow:**
```
Schedule (Daily) → Fetch Topics → Send to Ollama AI → 
Generate Content → Human Review Step → 
Publish to CMS → Post to Social Media
```

**Benefits:**
- Local AI generation (no API costs)
- Human-in-the-loop approval
- Multi-channel publishing
- Complete data control

### 5. DevOps Automation

**Workflow:**
```
Webhook (Alert) → Fetch Logs → Send to Ollama AI → 
Analyze Issue → Execute Remediation Script → 
Update Incident Tracker → Notify On-Call
```

**Benefits:**
- Intelligent incident response
- Automated remediation
- Integration with monitoring tools
- Execution history for post-mortems

---

## 📊 Deployment Details

| Configuration | Value |
|--------------|-------|
| **Install ID** | `{{ .nuon.install.id }}` |
| **Region** | `{{ .nuon.install_stack.outputs.region }}` |
| **Domain** | `{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}` |
| **Execution Mode** | {{ .nuon.inputs.inputs.executions_mode }} |
| **Worker Replicas** | {{ .nuon.inputs.inputs.worker_replicas }} |
| **Worker Concurrency** | {{ .nuon.inputs.inputs.worker_concurrency }} |
| **Database Storage** | {{ .nuon.inputs.inputs.db_storage_gb }}GB |
| **Workflow Storage** | {{ .nuon.inputs.inputs.workflow_storage_gb }}GB |
| **AI Storage** | {{ .nuon.inputs.inputs.ollama_storage_gb }}GB |
| **AI Model** | {{ .nuon.inputs.inputs.ollama_model }} |
| **Compute Nodes** | {{ .nuon.inputs.inputs.min_size }}-{{ .nuon.inputs.inputs.max_size }}x {{ .nuon.inputs.inputs.instance_size }} |
| **Log Level** | {{ .nuon.inputs.inputs.log_level }} |
| **Metrics Enabled** | {{ .nuon.inputs.inputs.enable_metrics }} |

---

## 📚 Resources

### n8n Documentation
- [Official Documentation](https://docs.n8n.io)
- [Workflow Templates](https://n8n.io/workflows)
- [Community Forum](https://community.n8n.io)
- [Node Reference](https://docs.n8n.io/integrations/builtin/)

### Ollama Documentation
- [Ollama Docs](https://ollama.ai/docs)
- [Model Library](https://ollama.ai/library)
- [API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md)

### Nuon Platform
- [Nuon Documentation](https://docs.nuon.co)
- [Example App Configs](https://github.com/nuonco/example-app-configs)
- [Nuon CLI](https://github.com/nuonco/nuon-cli)

### AWS Resources
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [ALB Ingress Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)

---

## 🔐 Security Considerations

### Network Security
- ✅ Isolated VPC per installation
- ✅ Ollama NOT exposed externally (cluster-internal only)
- ✅ TLS/SSL for all external traffic
- ✅ Security groups restrict access to necessary ports only

### Data Security
- ✅ Encrypted persistent volumes (EBS encryption)
- ✅ Secrets managed via Kubernetes secrets
- ✅ Database credentials rotatable
- ✅ All data stays in your AWS account

### Access Control
- ✅ IAM roles with least-privilege access (IRSA)
- ✅ Basic authentication enabled by default
- ✅ JWT support available
- ✅ Audit logs in CloudWatch

---

## 📈 Performance & Scaling

### Current Configuration

**Compute:**
- Instance Type: `{{ .nuon.inputs.inputs.instance_size }}`
- Min Nodes: `{{ .nuon.inputs.inputs.min_size }}`
- Max Nodes: `{{ .nuon.inputs.inputs.max_size }}`

**Workers:**
- Replicas: `{{ .nuon.inputs.inputs.worker_replicas }}`
- Concurrency: `{{ .nuon.inputs.inputs.worker_concurrency }}`
- Total Capacity: ~{{ mul .nuon.inputs.inputs.worker_replicas .nuon.inputs.inputs.worker_concurrency }} concurrent workflows

### Scaling Recommendations

| Workload | Workers | Instance Type | Notes |
|----------|---------|---------------|-------|
| **Light** (< 100 workflows/day) | 1-2 | t3.medium | Good for testing/dev |
| **Medium** (100-1000 workflows/day) | 2-4 | t3.large | Current config |
| **Heavy** (1000-10000 workflows/day) | 5-10 | t3.xlarge | Scale workers first |
| **Enterprise** (> 10000 workflows/day) | 10+ | m5.xlarge+ | Consider dedicated nodes |

---

## 💰 Cost Optimization

### Estimated Monthly Costs

**Small Deployment** (current config):
- EKS Control Plane: ~$75
- EC2 Nodes (2x t3.large): ~$150
- EBS Storage (80GB): ~$8
- ALB: ~$20
- Data Transfer: ~$10
- **Total: ~$263/month**

### Cost Reduction Tips

1. **Use Spot Instances** for worker nodes (workflows can tolerate interruptions)
2. **Scale down workers** during off-hours
3. **Enable execution data pruning** to reduce storage costs
4. **Use smaller AI models** (tinyllama vs mistral)
5. **Archive old backups** to S3 Glacier

---

## 🎉 Quick Start Checklist

- [ ] Access n8n interface at the URL above
- [ ] Change default password
- [ ] Run health check action
- [ ] Verify AI model is loaded (`pull_ollama_model` action)
- [ ] Create test workflow with AI node
- [ ] Configure webhook URL in external services
- [ ] Set up backup schedule (enabled by default)
- [ ] Configure monitoring alerts in CloudWatch
- [ ] Review and adjust worker scaling
- [ ] Document custom workflows and integrations

---

<details>
<summary>📦 Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

---

<p align="center">
  <strong>Powered by n8n + Ollama + Nuon</strong><br/>
  Questions? Contact support@nuon.co or visit <a href="https://nuon.co">nuon.co</a>
</p>
