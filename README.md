# AWS EKS FinanceGuard — PCI-DSS Compliant Platform

A production-grade, PCI-DSS compliant Kubernetes platform on AWS EKS for the finance industry. This monorepo manages infrastructure (Terraform), application deployment (Helm + ArgoCD GitOps), observability (OpenTelemetry, Prometheus, Grafana, Loki, Tempo), and security scanning (Checkov, Gitleaks, Semgrep) across three isolated environments.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Environment Summary](#environment-summary)
- [Full Lifecycle Commands](#full-lifecycle-commands)
  - [1. Infrastructure Provisioning (Terraform)](#1-infrastructure-provisioning-terraform)
  - [2. Cluster Access & kubeconfig](#2-cluster-access--kubeconfig)
  - [3. Application Deployment (Helm & GitOps)](#3-application-deployment-helm--gitops)
  - [4. Observability Stack](#4-observability-stack)
  - [5. Security Scanning](#5-security-scanning)
  - [6. GitOps Promotion (Dev → Staging → Prod)](#6-gitops-promotion-dev--staging--prod)
  - [7. Teardown & Destroy](#7-teardown--destroy)
- [CI/CD Pipelines](#cicd-pipelines)
- [Runbooks](#runbooks)
- [Contributing](#contributing)
- [License](#license)

---

## Architecture Overview

```

---

## Repository Structure

```
.
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Unified config (all 3 environments)
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── environments/           # Per-environment isolated configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── modules/
│       ├── network/            # VPC (wraps terraform-aws-modules/vpc)
│       ├── eks/                # EKS (wraps terraform-aws-modules/eks)
│       ├── ecr/                # Container registry (scaffold)
│       ├── rds/                # Database (scaffold)
│       └── observability-aws/  # AWS-native observability (scaffold)
├── helm/financeguard/          # Helm chart for the FinanceGuard app
├── gitops/
│   ├── argocd/                 # ArgoCD ApplicationSets & Projects
│   ├── environments/           # Per-env Helm value overrides + image digests
│   │   ├── dev/financeguard/
│   │   ├── staging/financeguard/
│   │   └── prod/financeguard/
│   └── policies/               # OPA/Kyverno policies
├── monitoring/observability/   # Grafana, Prometheus, Loki, Tempo, OTel configs
├── security/                   # Checkov, Gitleaks, Semgrep configs
├── ansible/                    # Configuration management playbooks
├── runbooks/                   # Incident response & operations runbooks
├── docs/                       # Architecture, compliance, security docs
└── .github/workflows/          # CI/CD pipelines
```

---

## Prerequisites

| Tool | Minimum Version | Install |
|------|----------------|---------|
| **Terraform** | >= 1.5.0 | [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads) |
| **AWS CLI** | v2 | [docs.aws.amazon.com/cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **kubectl** | 1.30+ | [kubernetes.io/docs](https://kubernetes.io/docs/tasks/tools/) |
| **Helm** | v3 | [helm.sh/docs](https://helm.sh/docs/intro/install/) |
| **ArgoCD CLI** | latest | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/en/stable/cli_installation/) |
| **Checkov** | latest | `pip install checkov` |
| **Gitleaks** | latest | `brew install gitleaks` or [GitHub releases](https://github.com/gitleaks/gitleaks/releases) |
| **Semgrep** | latest | `pip install semgrep` |

**AWS credentials** must be configured with sufficient IAM permissions:

```bash
# Configure AWS CLI profile
aws configure --profile financeguard
export AWS_PROFILE=financeguard
export AWS_REGION=us-east-1
```

---

## Environment Summary

| Property | Dev | Staging | Prod |
|----------|-----|---------|------|
| **Frontend VPC CIDR** | `10.12.0.0/16` | `10.11.0.0/16` | `10.10.0.0/16` |
| **Backend VPC CIDR** | `10.22.0.0/16` | `10.21.0.0/16` | `10.20.0.0/16` |
| **EKS Cluster** | `dev-eks-cluster` | `stage-eks-cluster` | `prod-eks-cluster` |
| **EKS VPC** | Backend | Backend | Backend |
| **K8s Version** | 1.30 | 1.30 | 1.30 |
| **Instance Type** | t3.medium | t3.large | m5.large |
| **Capacity** | SPOT | ON_DEMAND | ON_DEMAND |
| **Node Range** | 1 – 3 | 1 – 4 | 2 – 10 |
| **NAT Gateway** | Single (cost-optimized) | Single (cost-optimized) | Per-AZ (high availability) |
| **EBS Encryption** | Default | Default | ✅ Enforced (PCI-DSS) |
| **Terraform Dir** | `terraform/environments/dev` | `terraform/environments/stage` | `terraform/environments/prod` |

---

## Full Lifecycle Commands

> **Two provisioning approaches are available:**
> - **Unified** — Run from `terraform/` root to provision all three environments in a single apply.
> - **Per-Environment** — Run from `terraform/environments/<env>/` to manage each environment independently (recommended for production workflows).

---

### 1. Infrastructure Provisioning (Terraform)

#### Option A: Unified Deployment (All Environments)

```bash
# ── Initialize ──
cd terraform
terraform init

# ── Validate configuration ──
terraform validate

# ── Preview changes ──
terraform plan -out=tfplan

# ── Apply infrastructure ──
terraform apply tfplan

# ── Inspect outputs ──
terraform output
```

#### Option B: Per-Environment Deployment (Recommended)

##### Dev Environment

```bash
# ── Initialize ──
cd terraform/environments/dev
terraform init

# ── Validate ──
terraform validate

# ── Plan ──
terraform plan -out=dev.tfplan

# ── Apply ──
terraform apply dev.tfplan

# ── View outputs ──
terraform output
# Expected outputs: vpc_id, cluster_name, cluster_endpoint, cluster_arn
```

##### Staging Environment

```bash
# ── Initialize ──
cd terraform/environments/staging
terraform init

# ── Validate ──
terraform validate

# ── Plan ──
terraform plan -out=staging.tfplan

# ── Apply ──
terraform apply staging.tfplan

# ── View outputs ──
terraform output
```

##### Prod Environment

```bash
# ── Initialize ──
cd terraform/environments/prod
terraform init

# ── Validate ──
terraform validate

# ── Plan (review carefully — this is production) ──
terraform plan -out=prod.tfplan

# ── Apply (requires explicit approval) ──
terraform apply prod.tfplan

# ── View outputs ──
terraform output
```

##### Override Variables (Any Environment)

```bash
# Override region
terraform plan -var="aws_region=us-west-2" -out=tfplan

# Override Kubernetes version
terraform plan -var="kubernetes_version=1.31" -out=tfplan

# Prod: disable public API endpoint
terraform plan -var="cluster_endpoint_public_access=false" -out=tfplan
```

---

### 2. Cluster Access & kubeconfig

#### Dev

```bash
# Update kubeconfig for dev cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-eks-cluster \
  --alias dev

# Verify connectivity
kubectl --context dev get nodes
kubectl --context dev get namespaces

# Check cluster info
kubectl --context dev cluster-info
```

#### Staging

```bash
# Update kubeconfig for staging cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name stage-eks-cluster \
  --alias staging

# Verify connectivity
kubectl --context staging get nodes
kubectl --context staging get namespaces

# Check cluster info
kubectl --context staging cluster-info
```

#### Prod

```bash
# Update kubeconfig for prod cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name prod-eks-cluster \
  --alias prod

# Verify connectivity
kubectl --context prod get nodes
kubectl --context prod get namespaces

# Check cluster info
kubectl --context prod cluster-info
```

#### Switch Between Clusters

```bash
# List all contexts
kubectl config get-contexts

# Switch active context
kubectl config use-context dev
kubectl config use-context staging
kubectl config use-context prod

# Run a command against a specific context without switching
kubectl --context prod get pods -A
```

---

### 3. Application Deployment (Helm & GitOps)

#### Helm — Manual Deployment

##### Dev

```bash
# Install / upgrade FinanceGuard on dev
helm upgrade --install financeguard ./helm/financeguard \
  --namespace financeguard --create-namespace \
  --kube-context dev \
  -f gitops/environments/dev/financeguard/values.yaml \
  --set image.digest=$(cat gitops/environments/dev/financeguard/image-digest.yaml | grep digest | awk '{print $2}' | tr -d '"')

# Verify deployment
kubectl --context dev -n financeguard get pods
kubectl --context dev -n financeguard get svc

# Check rollout status
kubectl --context dev -n financeguard rollout status deployment/financeguard

# View Helm release
helm list --kube-context dev -n financeguard
```

##### Staging

```bash
# Install / upgrade FinanceGuard on staging
helm upgrade --install financeguard ./helm/financeguard \
  --namespace financeguard --create-namespace \
  --kube-context staging \
  -f gitops/environments/staging/financeguard/values.yaml \
  --set image.digest=$(cat gitops/environments/staging/financeguard/image-digest.yaml | grep digest | awk '{print $2}' | tr -d '"')

# Verify deployment
kubectl --context staging -n financeguard get pods
kubectl --context staging -n financeguard get svc

# Check rollout status
kubectl --context staging -n financeguard rollout status deployment/financeguard

# View Helm release
helm list --kube-context staging -n financeguard
```

##### Prod

```bash
# Install / upgrade FinanceGuard on prod
helm upgrade --install financeguard ./helm/financeguard \
  --namespace financeguard --create-namespace \
  --kube-context prod \
  -f gitops/environments/prod/financeguard/values.yaml \
  --set image.digest=$(cat gitops/environments/prod/financeguard/image-digest.yaml | grep digest | awk '{print $2}' | tr -d '"')

# Verify deployment
kubectl --context prod -n financeguard get pods
kubectl --context prod -n financeguard get svc

# Check rollout status
kubectl --context prod -n financeguard rollout status deployment/financeguard

# View Helm release
helm list --kube-context prod -n financeguard
```

#### ArgoCD — GitOps Deployment

```bash
# ── Bootstrap ArgoCD on each cluster ──

# Dev
kubectl --context dev create namespace argocd
kubectl --context dev apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Staging
kubectl --context staging create namespace argocd
kubectl --context staging apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Prod
kubectl --context prod create namespace argocd
kubectl --context prod apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ── Get ArgoCD admin password ──
kubectl --context <env> -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# ── Port-forward ArgoCD UI ──
kubectl --context <env> port-forward svc/argocd-server -n argocd 8080:443

# ── Login via CLI ──
argocd login localhost:8080 --username admin --password <password> --insecure

# ── Apply ArgoCD ApplicationSets (when configured) ──
kubectl --context <env> apply -f gitops/argocd/applicationsets/
kubectl --context <env> apply -f gitops/argocd/projects/

# ── Sync an application ──
argocd app sync financeguard-dev
argocd app sync financeguard-staging
argocd app sync financeguard-prod

# ── Check sync status ──
argocd app get financeguard-dev
argocd app get financeguard-staging
argocd app get financeguard-prod

# ── View application health ──
argocd app list
```

#### Helm — Rollback

```bash
# View release history
helm history financeguard --kube-context dev -n financeguard
helm history financeguard --kube-context staging -n financeguard
helm history financeguard --kube-context prod -n financeguard

# Rollback to previous revision
helm rollback financeguard <REVISION> --kube-context dev -n financeguard
helm rollback financeguard <REVISION> --kube-context staging -n financeguard
helm rollback financeguard <REVISION> --kube-context prod -n financeguard
```

---

### 4. Observability Stack

#### Install Observability Components

```bash
# ── Add Helm repositories ──
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

##### Dev

```bash
# Prometheus + Grafana (kube-prometheus-stack)
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --kube-context dev \
  --set grafana.enabled=true

# OpenTelemetry Collector
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --kube-context dev

# Loki (log aggregation)
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --kube-context dev \
  --set grafana.enabled=false

# Tempo (distributed tracing)
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --kube-context dev
```

##### Staging

```bash
# Prometheus + Grafana
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --kube-context staging \
  --set grafana.enabled=true

# OpenTelemetry Collector
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --kube-context staging

# Loki
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --kube-context staging \
  --set grafana.enabled=false

# Tempo
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --kube-context staging
```

##### Prod

```bash
# Prometheus + Grafana (with persistence for production)
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --kube-context prod \
  --set grafana.enabled=true \
  --set grafana.persistence.enabled=true \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi

# OpenTelemetry Collector
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --kube-context prod

# Loki (with persistence)
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --kube-context prod \
  --set grafana.enabled=false \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=50Gi

# Tempo (with persistence)
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --kube-context prod \
  --set persistence.enabled=true
```

#### Access Dashboards

```bash
# Port-forward Grafana (any environment)
kubectl --context dev port-forward svc/kube-prometheus-grafana -n monitoring 3000:80
kubectl --context staging port-forward svc/kube-prometheus-grafana -n monitoring 3000:80
kubectl --context prod port-forward svc/kube-prometheus-grafana -n monitoring 3000:80

# Get Grafana admin password
kubectl --context <env> get secret kube-prometheus-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo

# Port-forward Prometheus (any environment)
kubectl --context <env> port-forward svc/kube-prometheus-kube-prom-prometheus -n monitoring 9090:9090

# Apply custom Grafana dashboards (when configured)
kubectl --context <env> apply -f monitoring/observability/grafana/dashboards/
```

---

### 5. Security Scanning

#### Pre-Commit (Local Development)

```bash
# ── Terraform security scan with Checkov ──
checkov -d terraform/ --config-file security/.checkov.yml

# Scan a specific environment
checkov -d terraform/environments/dev/    --config-file security/.checkov.yml
checkov -d terraform/environments/staging/ --config-file security/.checkov.yml
checkov -d terraform/environments/prod/   --config-file security/.checkov.yml

# ── Secret detection with Gitleaks ──
gitleaks detect --source . --config security/.gitleaks.toml --verbose

# Scan only staged changes (pre-commit)
gitleaks protect --source . --config security/.gitleaks.toml --staged

# ── Static analysis with Semgrep ──
semgrep --config security/.semgrep.yml .

# Scan specific directories
semgrep --config security/.semgrep.yml terraform/
semgrep --config security/.semgrep.yml app/
semgrep --config security/.semgrep.yml gitops/
```

#### Runtime Security (On-Cluster)

```bash
# ── Verify pod security standards (any environment) ──
kubectl --context dev get pods -A -o json | jq '.items[] | {name: .metadata.name, namespace: .metadata.namespace}'
kubectl --context staging get pods -A -o json | jq '.items[] | {name: .metadata.name, namespace: .metadata.namespace}'
kubectl --context prod get pods -A -o json | jq '.items[] | {name: .metadata.name, namespace: .metadata.namespace}'

# ── Check for running containers as root ──
kubectl --context <env> get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].securityContext}{"\n"}{end}'

# ── Audit network policies ──
kubectl --context dev get networkpolicies -A
kubectl --context staging get networkpolicies -A
kubectl --context prod get networkpolicies -A
```

---

### 6. GitOps Promotion (Dev → Staging → Prod)

The promotion workflow follows a PR-based process through image digest updates:

```bash
# ── Step 1: Build & push image (CI automatically updates dev digest) ──
# The CI pipeline builds the container image and updates:
#   gitops/environments/dev/financeguard/image-digest.yaml

# ── Step 2: Promote Dev → Staging ──
# Copy the verified image digest from dev to staging
cp gitops/environments/dev/financeguard/image-digest.yaml \
   gitops/environments/staging/financeguard/image-digest.yaml

# Update environment reference in the digest file
sed -i 's/dev/staging/g' gitops/environments/staging/financeguard/image-digest.yaml

# Create a promotion PR
git checkout -b promote/staging-$(date +%Y%m%d-%H%M%S)
git add gitops/environments/staging/
git commit -m "chore: promote to staging — $(date +%Y-%m-%d)"
git push origin HEAD
# Open PR → CI validates → merge triggers ArgoCD sync

# ── Step 3: Promote Staging → Prod ──
# After staging validation passes, promote to prod
cp gitops/environments/staging/financeguard/image-digest.yaml \
   gitops/environments/prod/financeguard/image-digest.yaml

sed -i 's/staging/prod/g' gitops/environments/prod/financeguard/image-digest.yaml

git checkout -b promote/prod-$(date +%Y%m%d-%H%M%S)
git add gitops/environments/prod/
git commit -m "chore: promote to prod — $(date +%Y-%m-%d)"
git push origin HEAD
# Open PR → requires environment approval → merge triggers ArgoCD sync

# ── Or trigger the GitHub Actions promotion workflow ──
gh workflow run promote.yml
```

---

### 7. Teardown & Destroy

> ⚠️ **WARNING**: Destroy commands are irreversible. Always verify the plan output before confirming.

#### Per-Environment Teardown (Recommended)

##### Dev — Teardown

```bash
# Remove application workloads first
helm uninstall financeguard --kube-context dev -n financeguard
helm uninstall kube-prometheus --kube-context dev -n monitoring
helm uninstall otel-collector --kube-context dev -n monitoring
helm uninstall loki --kube-context dev -n monitoring
helm uninstall tempo --kube-context dev -n monitoring

# Remove ArgoCD
kubectl --context dev delete namespace argocd

# Destroy dev infrastructure
cd terraform/environments/dev
terraform plan -destroy -out=dev-destroy.tfplan
terraform apply dev-destroy.tfplan
```

##### Staging — Teardown

```bash
# Remove application workloads first
helm uninstall financeguard --kube-context staging -n financeguard
helm uninstall kube-prometheus --kube-context staging -n monitoring
helm uninstall otel-collector --kube-context staging -n monitoring
helm uninstall loki --kube-context staging -n monitoring
helm uninstall tempo --kube-context staging -n monitoring

# Remove ArgoCD
kubectl --context staging delete namespace argocd

# Destroy staging infrastructure
cd terraform/environments/staging
terraform plan -destroy -out=staging-destroy.tfplan
terraform apply staging-destroy.tfplan
```

##### Prod — Teardown

```bash
# Remove application workloads first
helm uninstall financeguard --kube-context prod -n financeguard
helm uninstall kube-prometheus --kube-context prod -n monitoring
helm uninstall otel-collector --kube-context prod -n monitoring
helm uninstall loki --kube-context prod -n monitoring
helm uninstall tempo --kube-context prod -n monitoring

# Remove ArgoCD
kubectl --context prod delete namespace argocd

# Destroy prod infrastructure (REQUIRES EXTRA CAUTION)
cd terraform/environments/prod
terraform plan -destroy -out=prod-destroy.tfplan

# Review the plan output thoroughly before proceeding
terraform apply prod-destroy.tfplan
```

#### Unified Teardown (All Environments)

```bash
# Remove all workloads from all clusters
for CTX in dev staging prod; do
  helm uninstall financeguard --kube-context $CTX -n financeguard 2>/dev/null || true
  helm uninstall kube-prometheus --kube-context $CTX -n monitoring 2>/dev/null || true
  helm uninstall otel-collector --kube-context $CTX -n monitoring 2>/dev/null || true
  helm uninstall loki --kube-context $CTX -n monitoring 2>/dev/null || true
  helm uninstall tempo --kube-context $CTX -n monitoring 2>/dev/null || true
  kubectl --context $CTX delete namespace argocd 2>/dev/null || true
done

# Destroy all infrastructure
cd terraform
terraform plan -destroy -out=destroy-all.tfplan
terraform apply destroy-all.tfplan
```

#### Clean Up Local State

```bash
# Remove kubeconfig entries
kubectl config delete-context dev
kubectl config delete-context staging
kubectl config delete-context prod

kubectl config delete-cluster arn:aws:eks:us-east-1:*:cluster/dev-eks-cluster
kubectl config delete-cluster arn:aws:eks:us-east-1:*:cluster/stage-eks-cluster
kubectl config delete-cluster arn:aws:eks:us-east-1:*:cluster/prod-eks-cluster
```

---

## CI/CD Pipelines

All workflows are defined in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **ci.yml** | PR on `app/**` | Application CI (build, test, scan) |
| **reusable-ci.yml** | `workflow_call` | Reusable secure build & scan |
| **terraform-plan.yml** | PR on `terraform/**` | Terraform plan validation |
| **terraform-apply.yml** | Push to `main` on `terraform/**` | Terraform apply |
| **terraform-drift.yml** | Daily cron (`0 0 * * *`) | Drift detection |
| **validate-gitops.yml** | PR on `gitops/**` | GitOps manifest validation |
| **promote.yml** | `workflow_dispatch` | Environment promotion |
| **release.yml** | Push to `main` | Release pipeline |
| **platform-validate.yml** | PR on `ansible/**`, `platform/**` | Platform config linting |
| **publish.yml** | Push changing `README.md` | Convert README to PDF, upload to S3 |

---

## Runbooks

| Runbook | Description |
|---------|-------------|
| [Deployment Rollback](runbooks/deployment-rollback.md) | Safe desired-state rollbacks via GitOps |
| [ArgoCD Recovery](runbooks/argocd-recovery.md) | Restore ArgoCD controller state |
| [Database Restore](runbooks/database-restore.md) | RDS PostgreSQL backup restore |
| [Disaster Recovery](runbooks/disaster-recovery.md) | Multi-AZ / regional DR playbook |
| [Secret Rotation](runbooks/secret-rotation.md) | Emergency & routine secret rotation |
| [Security Incident](runbooks/security-incident.md) | Triage & containment for runtime alerts |
| [Terraform State Recovery](runbooks/terraform-state-recovery.md) | State lock/corruption recovery |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on pull requests, issue reporting, and branching strategy.

All changes are gated by CI pipelines and require CODEOWNERS approval:

- **`/terraform/`** — `@financeguard-platform-team`
- **`/.github/workflows/`** — `@financeguard-secops-team`
- **Everything else** — `@financeguard-core-team`

---

## License

This project is licensed under the terms in [LICENSE](LICENSE).