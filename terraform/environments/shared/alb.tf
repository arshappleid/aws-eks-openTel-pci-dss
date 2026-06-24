module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "inspection-alb"
  vpc_id  = module.inspection_vpc.vpc_id
  subnets = module.inspection_vpc.public_subnets

  internal = false

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

  target_groups = merge(
    {
      default = {
        name_prefix = "def-"
        protocol    = "HTTP"
        port        = 80
        target_type = "ip"
        vpc_id      = module.inspection_vpc.vpc_id
        create_attachment = false
      }
    },
    {
      for service_name, service_config in var.services : "${service_name}-tg" => {
        name        = substr("tg-${service_name}", 0, 32)
        protocol    = "HTTP"
        port        = 80
        target_type = "ip"
        vpc_id      = module.inspection_vpc.vpc_id
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
          matcher             = "200"
        }
      }
    }
  )

  tags = local.common_tags
}


resource "aws_lb_listener_rule" "service_path_routing" {
  for_each = var.services

  listener_arn = module.alb.listeners["http-default"].arn
  priority     = each.value.alb_route_priority

  action {
    type             = "forward"
    target_group_arn = module.alb.target_groups["${each.key}-tg"].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }

  dynamic "transform" {
    for_each = each.value.strip_path_prefix ? [1] : []
    content {
      type = "url-rewrite"
      url_rewrite_config {
        rewrite {

          regex   = "^${replace(each.value.path_pattern, "