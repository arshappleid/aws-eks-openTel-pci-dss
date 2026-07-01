# prod/compute — variable values for the prod workspace
aws_region                     = "us-east-1"
env                            = "prod"
cluster_name                   = "financeguard-prod-frontend"
kubernetes_version             = "1.31"
cluster_endpoint_public_access = false
github_actions_role_arn        = "arn:aws:iam::866934333672:role/GITHUB-ACTIONS-ALL-REPO"
