{{ $region := .nuon.install_stack.outputs.region }}

<p align="center">
  <img src="https://community.n8n.io/uploads/default/original/3X/a/c/ac84cdc62ae7091365a95961177e16eb61b12b6e.gif" alt="n8n Workflow Automation" width="100%"/>
</p>

<h1 align="center">n8n with AI - Workflow Automation</h1>

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

# 🚀 Workflow automation in my own cloud

## 🌐 Your n8n Platform URL

**[https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})**



## 🔑 Default Login Credentials
```
Username: admin
Password: n8n-2024!
```
⚠️ Change this password after first login!

## 🤖 AI Configuration

Your n8n instance includes a built-in Ollama AI server for local model inference.

**Ollama Internal Endpoint:**
```
http://ollama-server.n8n.svc.cluster.local:11434
```

**Current AI Model:** `{{ .nuon.inputs.inputs.ollama_model }}`

**Using AI in Workflows:**
1. Add an **HTTP Request** node to your workflow
2. Set URL to: `http://ollama-server.n8n.svc.cluster.local:11434/api/generate`
3. Method: `POST`
4. Body:
   ```json
   {
     "model": "{{ .nuon.inputs.inputs.ollama_model }}",
     "prompt": "Your prompt here",
     "stream": false
   }
   ```

**Benefits:**
- ✅ No external API calls or costs
- ✅ Data never leaves your AWS account
- ✅ Low latency (local inference)
- ✅ No rate limits

### Quick Deploy

```bash
# 1. Sync the application
nuon apps sync --app n8n

# 2. Deploy to your AWS account
nuon installs deploy --app n8n --install-id {{ .nuon.install.id }}

# 3. Access your workflow automation (ready in ~10 minutes)
# https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
```

### ✨ Features

- **🤖 Built-in AI**: Integrated Ollama server for local AI inference (no API costs!)
- **🔒 100% Private**: All data and AI processing stays in your AWS account
- **🔌 350+ Integrations**: Connect Slack, Salesforce, Gmail, databases, APIs, and more
- **💰 No Per-Execution Costs**: Unlimited workflows on your infrastructure
- **⚡ Queue-Based Processing**: Redis-powered queue for reliable execution
- **📈 Multi-Worker Scaling**: Auto-scaling workers for parallel processing
- **🏢 Enterprise Ready**: SSL, monitoring, backups, and auto-scaling included

### 💡 Popular Use Cases

| Use Case | Example Workflow |
|----------|------------------|
| **🤖 AI Chat Assistant** | Chat trigger → Send to Ollama → Get AI response → Reply to user (100% local, no API costs!) |
| **📊 Lead Management** | New form submission → Validate data → Add to CRM → Notify sales team → Create follow-up task |
| **🛒 E-commerce Orders** | New order → Add customer to CRM → Send Slack notification → Create fulfillment task → Update inventory |
| **📈 Data Pipelines** | Schedule: Every hour → Fetch from APIs → Transform data → Store in database → Generate report → Email summary |
| **💬 Customer Support** | New ticket → AI analyzes sentiment → Route to team → Create tracking item → Send AI-generated reply |
| **📄 Document Processing** | New document → Extract text → Send to Ollama → Get AI analysis → Store results → Notify team |


### 🏗️ Architecture

```
Internet → ALB (HTTPS) → EKS Cluster
                              ↓
                    ┌─────────┴─────────┐
                    │                   │
                  n8n Main          n8n Workers
                    │                   │
                    └─────────┬─────────┘
                              ↓
                    ┌─────────┴─────────┐
                    │                   │
                PostgreSQL           Redis
                    │                   │
                    └─────────┬─────────┘
                              ↓
                    ┌─────────┴─────────┐
                    │                   │
              Ollama Server      S3 (Backups)
            (Local AI Models)
```

**Components:**
- **n8n Main**: Web UI and API server
- **n8n Workers**: Background workflow execution (scalable)
- **PostgreSQL**: Workflow and execution data storage
- **Redis**: Message queue and caching
- **Ollama Server**: Local AI model inference ({{ .nuon.inputs.inputs.ollama_model }} model)
- **S3**: Automated backups and file storage

### 📋 Deployment Details

| Component | Details |
|-----------|---------|
| **Install ID** | `{{ .nuon.install.id }}` |
| **Region** | `{{ .nuon.install_stack.outputs.region }}` |
| **Domain** | `{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}` |
| **Execution Mode** | {{ .nuon.inputs.inputs.executions_mode }} (queue-based) |
| **Workers** | {{ .nuon.inputs.inputs.worker_replicas }} replicas, {{ .nuon.inputs.inputs.worker_concurrency }} concurrency |
| **Storage** | {{ .nuon.inputs.inputs.db_storage_gb }}GB database, {{ .nuon.inputs.inputs.workflow_storage_gb }}GB workflows |
| **AI Storage** | {{ .nuon.inputs.inputs.ollama_storage_gb }}GB for AI models |
| **AI Model** | {{ .nuon.inputs.inputs.ollama_model }} |
| **Compute** | {{ .nuon.inputs.inputs.min_size }}-{{ .nuon.inputs.inputs.max_size }}x {{ .nuon.inputs.inputs.instance_size }} nodes |

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

### View Logs

Go to CloudWatch Logs in the AWS Console to monitor your workflows:

```txt
/aws/eks/{{ .nuon.install.id }}/n8n-main
/aws/eks/{{ .nuon.install.id }}/n8n-workers
```
## Resources

- [What is n8n?](https://n8n.io)
- [n8n Documentation](https://docs.n8n.io)
- [Workflow Templates](https://n8n.io/workflows)
- [Community Forum](https://community.n8n.io)
- [Nuon Platform](https://nuon.co)
