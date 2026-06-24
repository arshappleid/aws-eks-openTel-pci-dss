# Dynamic Environment-Specific API_URL Resolution

To resolve the frontend connection requirements across EKS environments where frontend and backend clusters are isolated in separate VPCs, we migrated from static Kubernetes manifests to a parameterized Helm chart driven by ArgoCD environment value overrides.

---

## 1. Unified Helm Chart: `helm/financeguard`

A single, generic Helm chart has been established to deploy either the frontend or backend tier dynamically:

*   [Chart.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/helm/financeguard/Chart.yaml): Initialized the chart metadata.
*   [values.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/helm/financeguard/values.yaml): Holds base default values.
*   [_helpers.tpl](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/helm/financeguard/templates/_helpers.tpl): Custom naming and labels generator templates.
*   [deployment.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/helm/financeguard/templates/deployment.yaml): Dynamic deployment mapping, including the container environment variables injected via `env`.
*   [service.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/helm/financeguard/templates/service.yaml): Dynamic service mapping to route incoming connections properly.

---

## 2. Environment Value Configurations

To point the frontend app to the correct backend route per environment, the `values.yaml` files inside each environment directory in GitOps override the frontend container's `API_URL`.

### Dev Environment
*   **Frontend Values**: [dev/financeguard/frontend/values.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/gitops/environments/dev/financeguard/frontend/values.yaml)
    ```yaml
    env:
      - name: API_URL
        value: "http://inspection-alb-564595949.us-east-1.elb.amazonaws.com/dev/api/"

    service:
      port: 80
      targetPort: 80
    ```
*   **Backend Values**: [dev/financeguard/backend/values.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/gitops/environments/dev/financeguard/backend/values.yaml)
    ```yaml
    env:
      - name: ENVIRONMENT
        value: "dev"
      - name: OTEL_EXPORTER_OTLP_ENDPOINT
        value: "http://otel-collector.financeguard.local:4317"
    ```

### Staging Environment
*   **Frontend Values**: [stage/financeguard/frontend/values.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/gitops/environments/stage/financeguard/frontend/values.yaml)
    ```yaml
    env:
      - name: API_URL
        value: "http://inspection-alb-564595949.us-east-1.elb.amazonaws.com/stage/api/"

    service:
      port: 80
      targetPort: 80
    ```
*   **Backend Values**: [stage/financeguard/backend/values.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/gitops/environments/stage/financeguard/backend/values.yaml)
    ```yaml
    env:
      - name: ENVIRONMENT
        value: "stage"
      - name: OTEL_EXPORTER_OTLP_ENDPOINT
        value: "http://otel-collector.financeguard.local:4317"
    ```

### Production Environment
*   **Frontend Values**: [prod/financeguard/frontend/values.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/gitops/environments/prod/financeguard/frontend/values.yaml)
    ```yaml
    env:
      - name: API_URL
        value: "http://inspection-alb-564595949.us-east-1.elb.amazonaws.com/prod/api/"

    service:
      port: 80
      targetPort: 80
    ```
*   **Backend Values**: [prod/financeguard/backend/values.yaml](file:///home/pdeol/code/github_projects/aws-eks-openTel-pci-dss/gitops/environments/prod/financeguard/backend/values.yaml)
    ```yaml
    env:
      - name: ENVIRONMENT
        value: "prod"
      - name: OTEL_EXPORTER_OTLP_ENDPOINT
        value: "http://otel-collector.financeguard.local:4317"
    ```

---

## 3. How the Runtime Inject Works
1.  **ArgoCD ApplicationSet** (`financeguard.yaml`) matches the generator matrix (`dev`, `stage`, `prod` combined with `frontend`, `backend`).
2.  It references `helm/financeguard` as the source chart.
3.  It pulls the corresponding `values.yaml` and `image-digest.yaml` from `gitops/environments/{{env}}/financeguard/{{tier}}/`.
4.  ArgoCD templates the Helm chart injecting the correct `API_URL` matching the target environment's ALB route (`/dev/api/`, `/stage/api/`, or `/prod/api/`).
5.  At container start, the frontend image's entrypoint script (`docker-entrypoint.sh`) writes the environment value into `/usr/share/nginx/html/env-config.js` as `window._env_.API_URL`.
6.  The React app (`App.js`) reads this dynamic runtime value on load in the client's browser.
