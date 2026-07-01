data "aws_vpc" "inspection" {
  filter {
    name   = "tag:Name"
    values = ["inspection-vpc"]
  }
}

data "aws_subnets" "inspection_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.inspection.id]
  }
  tags = {
    Purpose = "inspection-public"
  }
}

data "aws_subnets" "inspection_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.inspection.id]
  }
  tags = {
    Purpose = "inspection-firewall"
  }
}
