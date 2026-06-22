---
marp: true
theme: default
paginate: true
header: "FinanceGuard Infrastructure Overview"
footer: "Architecture & Observability Setup"
---

# FinanceGuard Infrastructure & Observability
**Comprehensive Systems Overview**

A deep dive into our Terraform, CI/CD, and Telemetry architecture.

---

# 🏗️ Core Infrastructure Architecture

- **AWS EKS Clusters:** Distinct clusters for `Frontend` and `Backend` applications across multiple environments (`dev`, `stage`, `prod`).
- **Transit Gateway Networking:** Hub-and-spoke VPC model connecting frontend, backend, and shared inspection VPCs.
- **Centralized Tagging:** All AWS resources are globally tagged (e.g., `Owner: Prabhmeet`) via Terraform's `default_tags` block to guarantee 100% tag coverage.
- **State Management:** Terraform state securely stored remotely in S3, leveraging native S3 conditional writes for state locking (no DynamoDB required!).

---

# 🚀 Automated CI/CD (GitHub Actions)

Robust, secure, and highly optimized deployment pipelines.

- **OIDC Authentication:** Zero hardcoded AWS credentials. GitHub Actions assumes an IAM Role using OpenID Connect (`AWS_ROLE_ARN`).
- **3-Tiered Workflows:**
  - `Plan`: Runs on Pull Requests.
  - `Apply`: Runs on pushes to `dev`, `stage`, and `prod` branches.
  - `Drift Detection`: Runs on a daily cron schedule to catch manual console changes.
- **Smart Path Filtering:** Pipelines use `paths-filter` to skip execution if no files in that specific environment/layer were modified.

---

# 🛡️ Bastion Server & Ingress

Secure point of entry and centralized monitoring dashboard.

- **Spot Instance Compute:** Runs on a `t3.micro` AWS Spot Instance, saving up to 90% on compute costs.
- **Network Placement:** Located in the shared Inspection VPC public subnet with a static Elastic IP (EIP).
- **Nginx Reverse Proxy:** Routes incoming traffic seamlessly on standard Port 80 based on URL sub-paths, hiding internal application ports from the internet.

---

# 📊 Observability Stack

A complete, Dockerized monitoring suite running on the Bastion server.

- **Prometheus:** Collects application and infrastructure metrics. Accessible via `/prometheus/`.
- **Grafana:** Visualizes metrics with custom dashboards. Accessible via `/grafana/`.
- **Jaeger:** Manages distributed request tracing. Accessible via `/jaeger/`.
- **Argo CD:** Manages Kubernetes application deployments, securely port-forwarded from the EKS clusters.

---

# 📡 Application Telemetry (FastAPI)

Zero-code auto-instrumentation using the **OpenTelemetry (OTel)** standard.

- **Metrics:** Replaces standard Prometheus clients. Automatically calculates Request Rates, Latency Histograms, and Error Rates.
- **Logs:** Injects trace context into standard Python logging, exporting directly to the OTel collector.
- **Traces:** Uses `FastAPIInstrumentor` to automatically trace every incoming HTTP request through the system.
- **Exporting:** Everything routes to a unified `OTEL_EXPORTER_OTLP_ENDPOINT`.

---

# 🌟 Key Security & Best Practices

- **Least-Privilege IAM:** GitHub Actions runs with a strictly scoped JSON policy governing EC2, EKS, KMS, and S3.
- **No Public EKS APIs:** Clusters are private; accessed securely via Bastion or authorized IAM roles.
- **Cost Optimization:** Automatic spot-instance fallback for non-critical infrastructure.
- **Infrastructure as Code (IaC):** 100% of the AWS infrastructure and GitHub Actions workflows are codified and version controlled.
