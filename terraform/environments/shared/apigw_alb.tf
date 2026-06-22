module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "inspection-alb"
  vpc_id  = module.inspection_vpc.vpc_id
  subnets = module.inspection_vpc.private_subnets

  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http-default = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "default"
      }
    }
  }

  target_groups = {
    default = {
      name_prefix = "def-"
      protocol    = "HTTP"
      port        = 80
      target_type = "ip"
      vpc_id      = module.inspection_vpc.vpc_id
      create_attachment = false
    }
  }

  tags = local.common_tags
}

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.0"

  name          = "inspection-api-gateway"
  description   = "HTTP API Gateway for inspection"
  protocol_type = "HTTP"

  create_domain_name = false

  vpc_links = {
    inspection-vpc = {
      name               = "inspection-vpc-link"
      security_group_ids = [module.alb.security_group_id]
      subnet_ids         = module.inspection_vpc.private_subnets
    }
  }

  tags = local.common_tags
}
