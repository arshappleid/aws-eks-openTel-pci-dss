# Provider configurations
# Version constraints are managed centrally in versions.tf (symlinked)

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner = "Prabhmeet"
    }
  }
}
