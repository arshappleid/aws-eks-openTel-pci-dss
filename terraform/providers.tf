# Provider configurations
# Version constraints are managed centrally in versions.tf

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner = "Prabhmeet"
    }
  }
}

provider "time" {}
