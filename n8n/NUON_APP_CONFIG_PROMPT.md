# 🚀 Nuon App Configuration - Complete Prompt & Runbook

> **Use this prompt when asking Cursor/AI to build a Nuon app configuration from scratch.**

---

## 📋 PROMPT TO GIVE TO CURSOR

Copy and paste the following prompt to Cursor when you want to build a new Nuon app:

---

```
I need you to create a complete Nuon app configuration for deploying [YOUR APPLICATION NAME] on AWS EKS.

## About Nuon

Nuon is a platform for deploying multi-tenant SaaS applications on Kubernetes. It uses:
- TOML configuration files for declarative infrastructure
- Helm charts for Kubernetes deployments  
- Go template variables ({{ .nuon.* }}) for dynamic configuration
- Components as deployment units with dependency management
- Actions for operational tasks (backups, maintenance, scaling)

## Required Files & Structure

Create the following directory structure:

```
app-name/
├── metadata.toml              # App metadata and description
├── inputs.toml                # User-configurable inputs (grouped)
├── secrets.toml               # Sensitive configuration (optional)
├── runner.toml                # Runner configuration (AWS-specific)
├── installer.toml             # Installer UI configuration
├── sandbox.toml               # Sandbox/infrastructure configuration
├── stack.toml                 # CloudFormation stack configuration
├── components/                # Component TOML definitions
│   ├── 1-component.toml       # Numbered for deployment order
│   ├── 2-component.toml
│   └── values/                # Helm values files
│       └── component-name/
│           └── values.yaml
├── src/
│   ├── components/            # Terraform modules
│   │   └── module-name/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── providers.tf
│   └── helm/                  # Custom Helm charts
│       └── chart-name/
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               └── deployment.yaml
├── actions/                   # Operational actions
│   └── action-name.toml
├── permissions/               # IAM permissions
│   ├── provision.toml
│   ├── maintenance.toml
│   ├── deprovision.toml
│   └── *_boundary.json
└── README.md                  # User-facing documentation
```

## Key Syntax Rules

### 1. TOML Files Must End with Trailing Newline
Every .toml file MUST end with exactly one blank line (trailing newline).

### 2. Template Variable Syntax
Use Go templates with these paths:
- {{ .nuon.install.inputs.<input_name> }} - User inputs
- {{ .nuon.install.secrets.<secret_name> }} - Secrets
- {{ .nuon.components.<component_name>.outputs.<output> }} - Component outputs
- {{ .nuon.install.sandbox.outputs.<key> }} - Sandbox outputs
- {{ .nuon.install.id }} - Install ID
- {{ .nuon.install_stack.outputs.region }} - AWS region

### 3. Component Dependencies
Components must list their dependencies explicitly:
dependencies = ["postgres_db", "redis"]

### 4. Use public_repo (not connected_repo)
For GitHub repositories:
[public_repo]
repo      = "org/repo-name"
directory = "path/to/source"
branch    = "main"

## Component Types

1. **terraform_module** - For AWS resources (S3, RDS, ACM, etc.)
2. **helm_chart** - For Kubernetes applications
3. **kubernetes_manifest** - For raw K8s YAML (ingress, configmaps)

## My Application Requirements

[DESCRIBE YOUR APPLICATION HERE]
- Main application: [name, docker image]
- Database: [PostgreSQL, MySQL, MongoDB, etc.]
- Cache/Queue: [Redis, RabbitMQ, etc.]
- Storage: [S3 buckets needed]
- Networking: [Ingress, load balancer, SSL]
- Optional services: [AI, monitoring, etc.]

Please create all the necessary files with proper syntax, dependencies, and best practices.
```

---

## 📁 COMPLETE FILE TEMPLATES

### 1. metadata.toml

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=metadata
version = "v2"

description = "Short description of your application - what it does and key features"
display_name = "Your Application Display Name"
readme       = "./README.md"

```

### 2. inputs.toml

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=inputs

# ============================================
# Input Groups - Organize related inputs
# ============================================

[[group]]
name         = "application"
description  = "Core application settings"
display_name = "Application Settings"

[[group]]
name         = "compute"
description  = "Compute and scaling configuration"
display_name = "Compute Resources"

[[group]]
name         = "database"
description  = "Database configuration"
display_name = "Database Settings"

[[group]]
name         = "cache"
description  = "Cache/queue configuration"
display_name = "Cache Settings"

[[group]]
name         = "storage"
description  = "Storage configuration"
display_name = "Storage Settings"

[[group]]
name         = "security"
description  = "Security and authentication"
display_name = "Security Settings"

[[group]]
name         = "monitoring"
description  = "Monitoring and observability"
display_name = "Monitoring Settings"

# ============================================
# Application Inputs
# ============================================

[[input]]
name         = "domain"
description  = "Domain name for the application (e.g., app.company.com)"
required     = true
display_name = "Application Domain"
group        = "application"

[[input]]
name         = "timezone"
description  = "Application timezone (e.g., UTC, America/New_York)"
default      = "UTC"
display_name = "Timezone"
group        = "application"

# ============================================
# Compute Inputs
# ============================================

[[input]]
name         = "instance_size"
description  = "AWS instance type (t3.medium, t3.large, t3.xlarge, m5.large)"
default      = "t3.large"
display_name = "Instance Size"
group        = "compute"

[[input]]
name         = "min_size"
description  = "Minimum number of nodes"
default      = "2"
display_name = "Minimum Nodes"
group        = "compute"

[[input]]
name         = "max_size"
description  = "Maximum number of nodes"
default      = "5"
display_name = "Maximum Nodes"
group        = "compute"

[[input]]
name         = "desired_capacity"
description  = "Desired number of nodes"
default      = "2"
display_name = "Desired Nodes"
group        = "compute"

# ============================================
# Database Inputs
# ============================================

[[input]]
name         = "db_storage_gb"
description  = "Database storage size in GB"
default      = "50"
display_name = "Database Storage (GB)"
group        = "database"

[[input]]
name         = "enable_db_backup"
description  = "Enable automated database backups (true/false)"
default      = "true"
display_name = "Enable Backups"
group        = "database"

[[input]]
name         = "db_backup_retention_days"
description  = "Backup retention period in days"
default      = "7"
display_name = "Backup Retention (days)"
group        = "database"

# ============================================
# Cache Inputs
# ============================================

[[input]]
name         = "redis_storage_gb"
description  = "Redis storage size in GB"
default      = "10"
display_name = "Redis Storage (GB)"
group        = "cache"

[[input]]
name         = "redis_persistence_enabled"
description  = "Enable Redis persistence (true/false)"
default      = "true"
display_name = "Redis Persistence"
group        = "cache"

# ============================================
# Monitoring Inputs
# ============================================

[[input]]
name         = "log_level"
description  = "Log level (error, warn, info, debug)"
default      = "info"
display_name = "Log Level"
group        = "monitoring"

[[input]]
name         = "enable_metrics"
description  = "Enable Prometheus metrics (true/false)"
default      = "true"
display_name = "Enable Metrics"
group        = "monitoring"

[[input]]
name         = "retention_days"
description  = "Log retention in days"
default      = "30"
display_name = "Log Retention (days)"
group        = "monitoring"

```

### 3. secrets.toml

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=secrets

# Secrets are sensitive values that users provide during installation
# Access via: {{ .nuon.install.secrets.<secret_name> }}

# NOTE: For initial development/testing, you can comment these out
# and use hardcoded values in your Helm values files.
# Uncomment for production use.

# [[secret]]
# name = "postgres_password"
# display_name = "PostgreSQL Password"
# description = "PostgreSQL database password"

# [[secret]]
# name = "redis_password"
# display_name = "Redis Password"
# description = "Redis password for authentication"

# [[secret]]
# name = "encryption_key"
# display_name = "Encryption Key"
# description = "Application encryption key (32+ characters)"

```

### 4. runner.toml

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=runner
runner_type     = "aws"
helm_driver     = "configmap"
init_script_url = "https://raw.githubusercontent.com/nuonco/runner/refs/heads/main/scripts/aws/init-mng.sh"

[env_vars]
# Environment variables available to all components
# Use template variables for dynamic values
LOG_LEVEL = "{{ .nuon.inputs.inputs.log_level }}"

```

### 5. installer.toml

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=installer
name                  = "your-app-installer"
description           = "One-click installer for Your Application"
documentation_url     = "https://docs.yourapp.com"
community_url         = "https://community.yourapp.com"
homepage_url          = "https://yourapp.com"
github_url            = "https://github.com/your-org/your-app"
logo_url              = "https://yourapp.com/logo.png"
favicon_url           = "https://yourapp.com/favicon.ico"

post_install_markdown = """
# 🎉 Your Application Successfully Installed!

## 🔗 Access Points
- **Application URL**: https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
- **API Endpoint**: https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/api/

## 🔑 Default Credentials
- **Username**: admin
- **Password**: Check your secrets management

## 📚 Getting Started
1. Visit the application URL
2. Log in with your credentials
3. Start using your application!

## 📖 Documentation
- Official Docs: https://docs.yourapp.com
"""

footer_markdown = """
---
*Powered by Your Application - Deployed with Nuon*
"""

copyright_markdown = "© 2024 Your Company. All rights reserved."

apps = []

```

### 6. sandbox.toml

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=sandbox
terraform_version = "1.11.3"

[public_repo]
directory = "."
repo      = "nuonco/aws-eks-sandbox"
branch    = "main"

[vars]
cluster_name         = "n-{{.nuon.install.id}}"
enable_nuon_dns      = "true"
public_root_domain   = "{{ .nuon.install.id }}.nuon.run"
internal_root_domain = "internal.{{ .nuon.install.id }}.nuon.run"

[[var_file]]
contents = "./sandbox.tfvars"

```

### 7. sandbox.tfvars

```hcl
additional_namespaces = ["your-namespace"]

min_size         = {{ .nuon.inputs.inputs.min_size }}
max_size         = {{ .nuon.inputs.inputs.max_size }}
desired_capacity = {{ .nuon.inputs.inputs.desired_capacity }}

# EKS access policies for maintenance role
maintenance_role_eks_access_entry_policy_associations = {
  eks_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
  eks_cluster_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
}

```

### 8. stack.toml

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=stack
type        = "aws-cloudformation"
name        = "nuon-yourapp-{{.nuon.install.id}}"
description = "QuickLink to install runner for Your Application: Install {{.nuon.install.id}}"

# Nested CloudFormation templates
vpc_nested_template_url    = "https://nuon-artifacts.s3.us-west-2.amazonaws.com/aws-cloudformation-templates/v0.1.6/vpc/eks/default/stack.yaml"
runner_nested_template_url = "https://nuon-artifacts.s3.us-west-2.amazonaws.com/aws-cloudformation-templates/v0.1.6/runner/asg/stack.yaml"

```

---

## 🧩 COMPONENT TEMPLATES

### Terraform Module Component

```toml
#:schema https://api.nuon.co/v1/general/config-schema?type=terraform
name              = "s3_buckets"
type              = "terraform_module"
terraform_version = "1.11.3"

[public_repo]
repo      = "your-org/your-repo"
directory = "app-name/src/components/s3_buckets"
branch    = "main"

[vars]
install_name          = "{{ .nuon.install.name }}"
region                = "{{ .nuon.install_stack.outputs.region }}"
install_id            = "{{ .nuon.install.id }}"
cluster_oidc_provider = "{{ .nuon.install.sandbox.outputs.cluster.oidc_provider }}"

```

### Helm Chart Component

```toml
#:schema https://api.nuon.co/v1/general/config-schema?type=helm
name           = "postgres_db"
type           = "helm_chart"
chart_name     = "postgresql"
namespace      = "your-namespace"
storage_driver = "configmap"
timeout        = "15m"
dependencies   = []  # List components this depends on

[public_repo]
repo      = "your-org/your-repo"
directory = "app-name/src/helm/postgresql"
branch    = "main"

[[values_file]]
contents = "./values/postgres/postgres.yaml"

```

### Kubernetes Manifest Component

```toml
#:schema https://api.nuon.co/v1/general/config-schema?type=kubernetes-manifest
name         = "alb_ingress"
type         = "kubernetes_manifest"
namespace    = "your-namespace"
dependencies = ["main_app", "certificate"]

manifest = """
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: your-namespace
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: "{{.nuon.components.certificate.outputs.certificate_arn}}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    external-dns.alpha.kubernetes.io/hostname: "{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}"
spec:
  rules:
    - host: "{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: your-app-service
                port:
                  number: 8080
"""

```

---

## 📦 HELM CHART TEMPLATES

### Chart.yaml

```yaml
apiVersion: v2
name: your-app
description: Your Application Description
type: application
version: 0.1.0
appVersion: "latest"
```

### values.yaml (Template with Nuon Variables)

```yaml
# Application Configuration
replicaCount: 1

image:
  repository: your-org/your-app
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

persistence:
  enabled: true
  size: {{ .nuon.install.inputs.storage_gb }}Gi
  storageClass: gp2

# Database Configuration
config:
  database:
    host: postgres-postgresql
    port: "5432"
    name: your_db
    user: app_user
    password: changeme123  # Use {{ .nuon.install.secrets.db_password }} in production

# Environment Variables
extraEnv:
  LOG_LEVEL: {{ .nuon.install.inputs.log_level }}
  METRICS_ENABLED: {{ .nuon.install.inputs.enable_metrics }}

# Resource Limits
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

```

### templates/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
        runAsGroup: 1000
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        env:
        - name: DATABASE_HOST
          value: "{{ .Values.config.database.host }}"
        - name: DATABASE_PORT
          value: "{{ .Values.config.database.port }}"
        - name: DATABASE_NAME
          value: "{{ .Values.config.database.name }}"
        - name: DATABASE_USER
          value: "{{ .Values.config.database.user }}"
        - name: DATABASE_PASSWORD
          value: "{{ .Values.config.database.password }}"
        {{- range $key, $value := .Values.extraEnv }}
        - name: {{ $key }}
          value: "{{ $value }}"
        {{- end }}
        ports:
        - containerPort: {{ .Values.service.port }}
          name: http
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        {{- if .Values.persistence.enabled }}
        volumeMounts:
        - name: data
          mountPath: /data
        {{- end }}
      {{- if .Values.persistence.enabled }}
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: {{ .Chart.Name }}-data
      {{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: {{ .Chart.Name }}
{{- if .Values.persistence.enabled }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Chart.Name }}-data
  namespace: {{ .Release.Namespace }}
spec:
  storageClassName: {{ .Values.persistence.storageClass }}
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end }}

```

---

## 🔧 TERRAFORM MODULE TEMPLATES

### main.tf (S3 Buckets Example)

```hcl
resource "aws_s3_bucket" "main" {
  bucket = "${var.install_id}-app-data"
  
  tags = {
    Name        = "${var.install_id}-app-data"
    ManagedBy   = "Nuon"
    InstallID   = var.install_id
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### variables.tf

```hcl
variable "install_id" {
  type        = string
  description = "Nuon install ID"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "install_name" {
  type        = string
  description = "Nuon install name"
}

variable "cluster_oidc_provider" {
  type        = string
  description = "EKS cluster OIDC provider"
}
```

### outputs.tf

```hcl
output "bucket_name" {
  value       = aws_s3_bucket.main.bucket
  description = "S3 bucket name"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "S3 bucket ARN"
}
```

### providers.tf

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
```

### Certificate Module (main.tf)

```hcl
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = [var.subject_alternative_names]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.install_id}-certificate"
    ManagedBy   = "Nuon"
  }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}
```

---

## ⚡ ACTION TEMPLATES

### Manual Action with Inputs

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=action

name    = "scale_workers"
timeout = "5m"
description = "Scale application workers up or down"

[[triggers]]
type = "manual"

[[inputs]]
name = "replica_count"
description = "Number of worker replicas"
required = true

[[steps]]
name = "scale"
inline_contents = """
#!/bin/bash
REPLICAS="{{ .action.inputs.replica_count }}"

echo "Scaling workers to $REPLICAS replicas..."
kubectl scale deployment/app-workers -n your-namespace --replicas=$REPLICAS

echo "Waiting for rollout..."
kubectl rollout status deployment/app-workers -n your-namespace --timeout=300s

echo "Current status:"
kubectl get pods -n your-namespace -l app=app-worker
"""

```

### Scheduled Action (Cron)

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=action

name    = "backup_database"
timeout = "15m"
description = "Create database backup and upload to S3"

[[triggers]]
type = "manual"

[[triggers]]
type = "cron"
schedule = "0 2 * * *"  # Daily at 2 AM UTC

[[steps]]
name = "create_backup"
inline_contents = """
#!/bin/bash
set -e

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${BACKUP_DATE}.sql"

echo "Creating database backup: $BACKUP_FILE"

# Get PostgreSQL pod
PG_POD=$(kubectl get pods -n your-namespace -l app=postgresql -o jsonpath='{.items[0].metadata.name}')

if [ -z "$PG_POD" ]; then
    echo "Error: PostgreSQL pod not found"
    exit 1
fi

# Create backup
kubectl exec -n your-namespace $PG_POD -- pg_dump -U dbuser -d dbname > /tmp/$BACKUP_FILE

# Upload to S3 (if enabled)
if [ "{{ .nuon.inputs.inputs.enable_s3_backup }}" = "true" ]; then
    echo "Uploading to S3..."
    aws s3 cp /tmp/$BACKUP_FILE s3://{{ .nuon.install.id }}-backups/$BACKUP_FILE
fi

echo "✅ Backup completed: $BACKUP_FILE"
"""

[[steps]]
name = "cleanup_old"
inline_contents = """
#!/bin/bash
RETENTION={{ .nuon.inputs.inputs.db_backup_retention_days }}

echo "Cleaning backups older than $RETENTION days..."

if [ "{{ .nuon.inputs.inputs.enable_s3_backup }}" = "true" ]; then
    # List and delete old backups
    aws s3 ls s3://{{ .nuon.install.id }}-backups/ | while read -r line; do
        FILE=$(echo $line | awk '{print $4}')
        if [ ! -z "$FILE" ]; then
            FILE_DATE=$(echo $FILE | grep -oP '\\d{8}')
            if [ ! -z "$FILE_DATE" ]; then
                AGE=$(( ($(date +%s) - $(date -d $FILE_DATE +%s)) / 86400 ))
                if [ $AGE -gt $RETENTION ]; then
                    echo "Deleting: $FILE (age: $AGE days)"
                    aws s3 rm s3://{{ .nuon.install.id }}-backups/$FILE
                fi
            fi
        fi
    done
fi

echo "✅ Cleanup completed"
"""

```

### Post-Deploy Health Check Action

```toml
#:schema https://api.nuon.co/v1/general/config-schema?source=action

name    = "health_check"
timeout = "5m"
description = "Check health status of all application components"

[[triggers]]
type = "manual"

[[triggers]]
type = "post-deploy-all-components"

[[steps]]
name = "check_pods"
inline_contents = """
#!/bin/bash
echo "=========================================="
echo "Checking Pod Status..."
echo "=========================================="
kubectl get pods -n your-namespace -o wide
echo ""
"""

[[steps]]
name = "check_services"
inline_contents = """
#!/bin/bash
echo "=========================================="
echo "Checking Services..."
echo "=========================================="
kubectl get svc -n your-namespace
echo ""
"""

[[steps]]
name = "check_storage"
inline_contents = """
#!/bin/bash
echo "=========================================="
echo "Checking Storage (PVCs)..."
echo "=========================================="
kubectl get pvc -n your-namespace
echo ""
"""

[[steps]]
name = "summary"
inline_contents = """
#!/bin/bash
echo "=========================================="
echo "Health Check Summary"
echo "=========================================="

TOTAL=$(kubectl get pods -n your-namespace --no-headers 2>/dev/null | wc -l)
RUNNING=$(kubectl get pods -n your-namespace --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

echo "Pods: $RUNNING/$TOTAL running"

APP_URL="https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}"
echo ""
echo "Access URL: $APP_URL"

if [ "$RUNNING" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo ""
    echo "✅ All systems operational"
else
    echo ""
    echo "⚠️ Some components need attention"
fi
"""

```

---

## 🔐 PERMISSIONS TEMPLATES

### permissions/provision.toml

```toml
type = "provision"
name = "{{.nuon.install.id}}-provision"
description = "provision"
display_name = "provision"
permissions_boundary = "./provision_boundary.json"

[[policies]]
managed_policy_name = "AdministratorAccess"

```

### permissions/maintenance.toml

```toml
type = "maintenance"
name = "{{ .nuon.install.id }}-maintenance"
description = "maintenance"
display_name = "maintenance"
permissions_boundary = "./maintenance_boundary.json"

[[policies]]
managed_policy_name = "AdministratorAccess"

```

### permissions/deprovision.toml

```toml
type = "deprovision"
name = "{{.nuon.install.id}}-deprovision"
description = "deprovision"
display_name = "deprovision"
permissions_boundary = "./deprovision_boundary.json"

[[policies]]
managed_policy_name = "AdministratorAccess"

```

### permissions/*_boundary.json (All Same)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}

```

---

## 📐 COMMON DEPENDENCY PATTERNS

### Pattern 1: Standard Web App
```
1. s3_buckets (no deps)
2. certificate (no deps)  
3. postgres_db (no deps)
4. redis (no deps)
5. main_app (deps: postgres_db, redis)
6. workers (deps: main_app, postgres_db, redis)
7. ingress (deps: main_app, certificate)
```

### Pattern 2: With External AI
```
1. s3_buckets (no deps)
2. certificate (no deps)
3. postgres_db (no deps)
4. redis (no deps)
5. ollama_server (no deps)
6. main_app (deps: postgres_db, redis, ollama_server)
7. workers (deps: main_app)
8. ingress (deps: main_app, certificate)
```

### Pattern 3: Minimal App
```
1. certificate (no deps)
2. postgres_db (no deps)
3. main_app (deps: postgres_db)
4. ingress (deps: main_app, certificate)
```

---

## ⚠️ CRITICAL RULES & COMMON MISTAKES

### MUST DO:

1. **End all TOML files with a blank line** (trailing newline)
2. **Commit and push to Git before deploying** - Nuon pulls from Git
3. **Use snake_case for component names** - `postgres_db`, not `postgres-db`
4. **Prefix component files with numbers** - `1-postgres.toml`, `2-redis.toml`
5. **List ALL dependencies explicitly** - Components only see their dependencies' outputs
6. **Use `public_repo` not `connected_repo`** for GitHub source references
7. **Escape backslashes in TOML multiline strings** - Use `\\d` not `\d`

### MUST NOT:

1. **Don't use deprecated template syntax:**
   - ❌ `{{ .nuon.inputs.inputs.name }}`
   - ✅ `{{ .nuon.install.inputs.name }}`

2. **Don't use `public_chart`** - Use custom Helm charts with `public_repo`

3. **Don't forget the schema line** at the top of TOML files

4. **Don't use circular dependencies** - A → B → C → A is invalid

5. **Don't hardcode install IDs or domains** - Always use template variables

### Template Variable Quick Reference:

| What You Need | Template Path |
|--------------|---------------|
| User input | `{{ .nuon.install.inputs.<name> }}` |
| Secret | `{{ .nuon.install.secrets.<name> }}` |
| Component output | `{{ .nuon.components.<comp>.outputs.<key> }}` |
| Install ID | `{{ .nuon.install.id }}` |
| Install name | `{{ .nuon.install.name }}` |
| AWS region | `{{ .nuon.install_stack.outputs.region }}` |
| Public domain | `{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}` |
| Zone ID | `{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.zone_id }}` |
| OIDC provider | `{{ .nuon.install.sandbox.outputs.cluster.oidc_provider }}` |
| Action input | `{{ .action.inputs.<name> }}` |

---

## 🚀 DEPLOYMENT WORKFLOW

### Step 1: Create Files
Use the templates above to create all necessary files.

### Step 2: Validate TOML Syntax
```bash
# Check for trailing newlines
for f in $(find . -name "*.toml"); do
  [ -n "$(tail -c 1 "$f")" ] && echo "Missing newline: $f"
done
```

### Step 3: Commit to Git
```bash
git add -A
git commit -m "Add Nuon app configuration"
git push origin main
```

### Step 4: Sync with Nuon
```bash
nuon sync
```

### Step 5: Deploy Components Incrementally
```bash
# Deploy infrastructure first
nuon plan s3_buckets && nuon apply s3_buckets
nuon plan certificate && nuon apply certificate

# Then databases
nuon plan postgres_db && nuon apply postgres_db
nuon plan redis && nuon apply redis

# Then application
nuon plan main_app && nuon apply main_app
nuon plan workers && nuon apply workers

# Finally networking
nuon plan ingress && nuon apply ingress
```

### Step 6: Verify Deployment
```bash
kubectl get pods -n your-namespace
kubectl get svc,ingress -n your-namespace
curl https://your-app-url/healthz
```

---

## 🎯 CHECKLIST FOR NEW APP CONFIGS

- [ ] `metadata.toml` - App description and readme path
- [ ] `inputs.toml` - All user-configurable inputs with groups
- [ ] `secrets.toml` - Sensitive values (or commented for dev)
- [ ] `runner.toml` - AWS runner config with env vars
- [ ] `installer.toml` - Installer UI configuration
- [ ] `sandbox.toml` - EKS sandbox configuration
- [ ] `sandbox.tfvars` - Terraform variables for sandbox
- [ ] `stack.toml` - CloudFormation stack config
- [ ] `components/*.toml` - All component definitions
- [ ] `components/values/*/*.yaml` - Helm values files
- [ ] `src/helm/*/` - Custom Helm charts with Chart.yaml, values.yaml, templates/
- [ ] `src/components/*/` - Terraform modules (if needed)
- [ ] `actions/*.toml` - Operational actions
- [ ] `permissions/*.toml` - IAM permission configs
- [ ] `permissions/*_boundary.json` - IAM boundaries
- [ ] `README.md` - User documentation with Nuon template variables
- [ ] All TOML files end with trailing newline
- [ ] All files committed and pushed to Git

---

**This runbook is based on a production n8n deployment with PostgreSQL, Redis, Ollama AI, and ALB ingress.**
