# Custom network module wrapping Anton Babenko's AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = var.tags
}

# ==============================================================================
# Transit Gateway Integration (VPC Attachment and Route Configuration)
# ==============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = var.transit_gateway_id != null && var.transit_gateway_id != "" ? 1 : 0

  transit_gateway_id = var.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  # Disable default association and propagation to enforce manual configuration (PCI-DSS compliance)
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-tgw-attachment"
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count = (var.transit_gateway_id != null && var.transit_gateway_id != "" && 
           var.transit_gateway_route_table_association_id != null && var.transit_gateway_route_table_association_id != "") ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_association_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  count = (var.transit_gateway_id != null && var.transit_gateway_id != "" && 
           var.transit_gateway_route_table_propagation_id != null && var.transit_gateway_route_table_propagation_id != "") ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_propagation_id
}

locals {
  # Generate list of combinations for VPC route tables and TGW destination CIDRs
  vpc_route_tables = var.transit_gateway_id != null && var.transit_gateway_id != "" ? concat(
    module.vpc.private_route_table_ids,
    module.vpc.public_route_table_ids
  ) : []

  tgw_routes = flatten([
    for rt_id in local.vpc_route_tables : [
      for dest in var.tgw_destinations : {
        route_table_id = rt_id
        destination    = dest
      }
    ]
  ])
}

resource "aws_route" "tgw" {
  for_each = { for idx, r in local.tgw_routes : "${r.route_table_id}-${r.destination}" => r }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination
  transit_gateway_id     = var.transit_gateway_id
}

