locals {
  common_tags = merge(var.common_tags, { Environment = "shared" })
}

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
  tags = { Purpose = "inspection-public" }
}

data "aws_subnets" "inspection_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.inspection.id]
  }
  tags = { Purpose = "inspection-firewall" }
}

data "aws_service_discovery_dns_namespace" "internal" {
  name = "financeguard.local"
  type = "DNS_PRIVATE"
}

data "aws_service_discovery_service" "otel_collector" {
  name         = "otel-collector"
  namespace_id = data.aws_service_discovery_dns_namespace.internal.id
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "inspection-alb"
  vpc_id  = data.aws_vpc.inspection.id
  subnets = data.aws_subnets.inspection_public.ids

  internal                   = false
  enable_deletion_protection = false

  access_logs = {
    bucket  = "prab-terraform-backend"
    enabled = true
    prefix  = "eks-project/frontend-alb"
  }

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
    all = { ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
  }

  listeners = {
    http-default = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = "default" }
    }
  }

  target_groups = merge(
    {
      default = {
        name_prefix       = "def-"
        protocol          = "HTTP"
        port              = 80
        target_type       = "ip"
        vpc_id            = data.aws_vpc.inspection.id
        create_attachment = false
      }
    },
    {
      for service_name, service_config in var.services : "${service_name}-tg" => {
        name              = substr("tg-${service_name}", 0, 32)
        protocol          = "HTTP"
        port              = 80
        target_type       = "ip"
        vpc_id            = data.aws_vpc.inspection.id
        create_attachment = false
        tags = {
          "eks:eks-cluster-name" = "financeguard-${split("-", service_name)[1]}-${split("-", service_name)[0]}"
        }
        health_check = {
          enabled             = true
          interval            = 30
          path                = service_config.health_check_path
          port                = "traffic-port"
          healthy_threshold   = 2
          unhealthy_threshold = 3
          timeout             = 6
          protocol            = "HTTP"
          matcher             = "200-399"
        }
      }
    }
  )

  tags = local.common_tags
}

resource "aws_lb_listener_rule" "service_path_routing" {
  for_each     = var.services
  listener_arn = module.alb.listeners["http-default"].arn
  priority     = each.value.alb_route_priority

  action {
    type             = "forward"
    target_group_arn = module.alb.target_groups["${each.key}-tg"].arn
  }

  condition {
    path_pattern { values = [each.value.path_pattern] }
  }

  dynamic "transform" {
    for_each = each.value.strip_path_prefix ? [1] : []
    content {
      type = "url-rewrite"
      url_rewrite_config {
        rewrite {
          regex   = "^${replace(each.value.path_pattern, "/*", "")}/(.*)$"
          replace = "/$1"
        }
      }
    }
  }

  tags = local.common_tags
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = data.aws_vpc.inspection.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Nginx HTTP Reverse Proxy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow all traffic from private CIDRs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "192.178.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "bastion-sg" })
}

resource "aws_iam_role" "bastion" {
  name = "bastion-server-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = merge(local.common_tags, { Name = "bastion-server-role" })
}

resource "aws_iam_policy" "bastion_s3" {
  name        = "bastion-s3-logs-read-policy"
  description = "Allows Bastion host to read logs from prab-infrastrcuture-logs bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = ["arn:aws:s3:::prab-infrastrcuture-logs", "arn:aws:s3:::prab-infrastrcuture-logs/*"]
    }]
  })
  tags = merge(local.common_tags, { Name = "bastion-s3-logs-read-policy" })
}

resource "aws_iam_policy" "bastion_eks" {
  name        = "bastion-eks-access-policy"
  description = "Allows Bastion host to interact with EKS clusters"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Resource = "*"
    }]
  })
  tags = merge(local.common_tags, { Name = "bastion-eks-access-policy" })
}

resource "aws_iam_role_policy_attachment" "bastion_s3" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_s3.arn
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_eks" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_eks.arn
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-server-instance-profile"
  role = aws_iam_role.bastion.name
  tags = merge(local.common_tags, { Name = "bastion-server-instance-profile" })
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  key_name      = "prab-key-pair"

  instance_market_options { market_type = "spot" }

  subnet_id              = data.aws_subnets.inspection_public.ids[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  user_data                   = file("${path.module}/bastion-init.sh")
  user_data_replace_on_change = true

  tags = merge(local.common_tags, { Name = "bastion-server" })
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "bastion-eip" })
}

resource "aws_service_discovery_instance" "bastion_otel" {
  instance_id = aws_instance.bastion.id
  service_id  = data.aws_service_discovery_service.otel_collector.id
  attributes  = { AWS_INSTANCE_IPV4 = aws_instance.bastion.private_ip }
}
