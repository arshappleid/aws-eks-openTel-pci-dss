# Fetch the Route 53 Private Hosted Zone created by Cloud Map in the Shared environment
data "aws_route53_zone" "service_discovery" {
  name         = "financeguard.local."
  private_zone = true
}

# Associate the Frontend VPC with the Service Discovery zone
resource "aws_route53_zone_association" "frontend" {
  zone_id = data.aws_route53_zone.service_discovery.zone_id
  vpc_id  = module.frontend_network.vpc_id
}

# Associate the Backend VPC with the Service Discovery zone
resource "aws_route53_zone_association" "backend" {
  zone_id = data.aws_route53_zone.service_discovery.zone_id
  vpc_id  = module.backend_network.vpc_id
}
