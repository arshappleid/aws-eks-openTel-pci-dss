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


---

## Development Commands
```
docker compose up -d
docker exec -it terraform_env /bin/bash
aws login --remote
cd environments/shared/compute
terraform apply --auto-approve
```

## Environment Summary

| Property | Dev | Staging | Prod |
|----------|-----|---------|------|
| **Frontend VPC CIDR** | `10.12.0.0/16` | `10.11.0.0/16` | `10.10.0.0/16` |
| **Backend VPC CIDR** | `10.22.0.0/16` | `10.21.0.0/16` | `10.20.0.0/16` |
| **EKS Clusters** | `financeguard-dev-frontend`<br>`financeguard-dev-backend` | `financeguard-staging-frontend`<br>`financeguard-staging-backend` | `financeguard-prod-frontend`<br>`financeguard-prod-backend` |
| **EKS VPC** | Frontend & Backend | Frontend & Backend | Frontend & Backend |
| **K8s Version** | 1.30 | 1.30 | 1.30 |
| **Instance Type** | `t3.medium` | `t3.large` | `m5.large` |
| **Capacity** | SPOT | SPOT | ON_DEMAND |
| **Node Range** | 2 – 4 | 2 – 6 | 2 – 10 |
| **NAT Gateway** | Single (cost-optimized) | None (Frontend) / Single (Backend) | Per-AZ (high availability) |
| **EBS Encryption** | Default | Default | Enforced (PCI-DSS) |
| **Terraform Dir** | `terraform/environments/dev` | `terraform/environments/stage` | `terraform/environments/prod` |

---



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