# Root Terraform Configuration (Unified Wrapper)
# This configuration calls the shared and environment configurations as modules.
# It allows running a single apply from the root, while keeping their states
# and lifecycles modularized and decoupled.

locals {
  common_tags = {
    Project   = "aws-eks-openTel-pci-dss"
    ManagedBy = "Terraform"
  }
}

# 1. SHARED CORE NETWORK (Transit Gateway and Inspection VPC Hub)
module "shared" {
  source     = "./environments/shared"
  aws_region = var.aws_region
}

# 2. PROD ENVIRONMENT
module "prod" {
  source                         = "./environments/prod"
  aws_region                     = var.aws_region
  kubernetes_version             = var.kubernetes_version
  cluster_endpoint_public_access = var.prod_cluster_endpoint_public_access

  # Ensure the Transit Gateway and Route Tables exist first
  depends_on = [module.shared]
}

# 3. STAGE ENVIRONMENT
module "stage" {
  source             = "./environments/stage"
  aws_region         = var.aws_region
  kubernetes_version = var.kubernetes_version

  # Ensure the Transit Gateway and Route Tables exist first
  depends_on = [module.shared]
}

# 4. DEV ENVIRONMENT
module "dev" {
  source             = "./environments/dev"
  aws_region         = var.aws_region
  kubernetes_version = var.kubernetes_version

  # Ensure the Transit Gateway and Route Tables exist first
  depends_on = [module.shared]
}
