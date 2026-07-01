# AWS EKS FinanceGuard — PCI-DSS Compliant Platform

A production-grade, PCI-DSS compliant Kubernetes platform on AWS EKS for the finance industry. This monorepo manages infrastructure (Terraform), application deployment (Helm + ArgoCD GitOps), observability (OpenTelemetry, Prometheus, Grafana, Loki, Tempo), and security scanning (Checkov, Gitleaks, Semgrep) across three isolated environments.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Development Commands](#development-commands)
- [Environment Summary](#environment-summary)
- [Contributing](#contributing)
- [License](#license)

---

## Architecture Overview

Architecture diagram and details will be added here.

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
│   │   │   ├── network/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf    # type declarations only (no defaults)
│   │   │   │   └── dev.tfvars      # ← environment-specific values
│   │   │   ├── compute/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── dev.tfvars
│   │   │   └── kubernetes/
│   │   │       ├── main.tf
│   │   │       ├── variables.tf
│   │   │       └── dev.tfvars
│   │   ├── stage/              # Same structure; stage.tfvars per layer
│   │   ├── prod/               # Same structure; prod.tfvars per layer
│   │   └── shared/
│   │       ├── network/
│   │       │   └── shared.tfvars  # Shared-network values (inspection VPC)
│   │       └── compute/
│   │           └── shared.tfvars  # Shared-compute values (Bastion/ALB)
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
│   │   ├── stage/financeguard/
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

**AWS credentials** must be configured with sufficient IAM permissions. (e.g., via `aws configure` or `aws sso login`)

---

## Terraform Workspace Demo (dev environment)

This repo uses **Terraform workspaces** with per-environment `.tfvars` files.  
All variable values live in `terraform/environments/<env>/<layer>/<env>.tfvars`; the `.tf` files themselves contain no hardcoded defaults.

### Running `terraform apply` for `dev/network`

```bash
# 1. Start the Terraform Docker environment (optional — skip if using local TF install)
docker compose up -d
docker exec -it terraform_env /bin/bash

# 2. Authenticate to AWS
aws sso login   # or: aws configure

# 3. Move into the dev network layer
cd terraform/environments/dev/network

# 4. Initialise with the remote S3 backend
terraform init \
  -backend-config="bucket=prab-terraform-backend" \
  -backend-config="key=eks-project/tfstate/dev/network/terraform.tfstate" \
  -backend-config="region=us-east-1"

# 5. Select (or create) the dev workspace
terraform workspace select dev || terraform workspace new dev

# 6. Preview changes — var-file supplies all environment-specific values
terraform plan -var-file="dev.tfvars"

# 7. Apply
terraform apply -var-file="dev.tfvars" -auto-approve
```

> **Switching environments** is a one-liner: replace `dev` with `stage` or `prod` in the path and workspace name, and point `-var-file` at the matching `.tfvars`.

```bash
# Example: run the same layer for staging
cd terraform/environments/stage/network
terraform workspace select stage || terraform workspace new stage
terraform plan  -var-file="stage.tfvars"
terraform apply -var-file="stage.tfvars" -auto-approve
```

## Environment Summary

| Property | Dev | Staging | Prod |
|----------|-----|---------|------|
| **Frontend VPC CIDR** | `10.12.0.0/16` | `10.11.0.0/16` | `10.10.0.0/16` |
| **Backend VPC CIDR** | `10.22.0.0/16` | `10.21.0.0/16` | `10.20.0.0/16` |
| **EKS Clusters** | financeguard-dev-frontend<br />financeguard-dev-backend | financeguard-stage-frontend<br />financeguard-stage-backend | financeguard-prod-frontend<br />financeguard-prod-backend |
| **EKS VPC** | Frontend & Backend | Frontend & Backend | Frontend & Backend |
| **K8s Version** | 1.30 | 1.30 | 1.30 |
| **Instance Type** | `t3.medium` | `t3.large` | `m5.large` |
| **Capacity** | SPOT | SPOT | ON_DEMAND |
| **Node Range** | 2 - 4 | 2 - 6 | 2 - 10 |
| **NAT Gateway** | Single (cost-optimized) | None (Frontend) / Single (Backend) | Per-AZ (high availability) |
| **EBS Encryption** | Default | Default | Enforced (PCI-DSS) |
| **Terraform Dir** | `terraform/environments/dev` | `terraform/environments/stage` | `terraform/environments/prod` |

---

## Observability & Dashboards

All monitoring, metrics, logging, tracing, and continuous delivery tools are hosted on the central Bastion server in the shared Inspection VPC. They are securely reverse-proxied by Nginx on Port 80:

| Dashboard | URL | Purpose |
|-----------|-----|---------|
| **Grafana** | `http://<bastion-ip>/grafana/` <br />(or root `http://<bastion-ip>/`) | Central metrics & logs visualization dashboard |
| **Prometheus** | `http://<bastion-ip>/prometheus/` | Scraping status, target health, and query editor |
| **Jaeger** | `http://<bastion-ip>/jaeger/` | Distributed tracing search and dependency graphs |
| **Loki** | `http://<bastion-ip>/loki/` | Container log ingestion api path |
| **Argo CD** | `http://<ALB_DNS_NAME>/argocd/` | GitOps continuous delivery console. Username is `admin`, password is in the `argocd-initial-admin-secret` Kubernetes secret. |


---

## Cost Estimate Matrix

The following table summarizes the estimated AWS infrastructure costs across all environments (based on standard `us-east-1` pricing):

| Environment | Primary Resources | Compute Type | Daily Cost (Est.) | Monthly Cost (Est.) |
|-------------|-------------------|--------------|-------------------|---------------------|
| **Shared (Inspection)** | 1x `t3.large` Bastion, 1x ALB, 1x NAT Gateway, Transit Gateway Router | Spot / Pay-per-use | ~$6.12 | ~$186.02 |
| **Dev** | 2x EKS Clusters, 4x `t3.medium` worker nodes, 2x NAT Gateways | Spot (Nodes) | ~$11.06 | ~$336.20 |
| **Stage** | 2x EKS Clusters, 4x `t3.large` worker nodes, 2x NAT Gateways | Spot (Nodes) | ~$12.36 | ~$375.70 |
| **Prod** | 2x EKS Clusters, 6x `m5.large` worker nodes, 6x NAT Gateways (Multi-AZ) | On-Demand (HA) | ~$29.00 | ~$881.58 |
| **Total Project** | **All environments running concurrently** | **Hybrid** | **~$58.54** | **~$1,779.50** |

> [!TIP]
> * Dev and Stage environments utilize AWS Spot Instances for worker nodes, reducing compute costs by up to 75%.
> * Prod environment enforces On-Demand compute and Multi-AZ NAT Gateways to meet strict PCI-DSS Availability and HA constraints.

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