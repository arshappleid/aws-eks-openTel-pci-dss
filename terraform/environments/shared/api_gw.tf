module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.0"

  name          = "prab-eks-frontend-api-gateway"
  description   = "HTTP API Gateway for inspection"
  protocol_type = "HTTP"

  create_domain_name = false

  stage_access_log_settings = {
	destination_arn = var.api_gateway_access_log_group_arn
    create_log_group            = false
    log_group_retention_in_days = 7
    format = jsonencode({
      context = {
        domainName              = "$context.domainName"
        integrationErrorMessage = "$context.integrationErrorMessage"
        protocol                = "$context.protocol"
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        responseLength          = "$context.responseLength"
        routeKey                = "$context.routeKey"
        stage                   = "$context.stage"
        status                  = "$context.status"
        error = {
          message      = "$context.error.message"
          responseType = "$context.error.responseType"
        }
        identity = {
          sourceIP = "$context.identity.sourceIp"
        }
        integration = {
          error             = "$context.integration.error"
          integrationStatus = "$context.integration.integrationStatus"
        }
      }
    })
  }


  vpc_links = {
    inspection-vpc = {
      name               = "inspection-vpc-link"
      security_group_ids = [module.alb.security_group_id]
      subnet_ids         = module.inspection_vpc.private_subnets
    }
  }

  tags = local.common_tags
}