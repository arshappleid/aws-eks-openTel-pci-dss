


provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner = "Prabhmeet"
    }
  }
}

provider "time" {}