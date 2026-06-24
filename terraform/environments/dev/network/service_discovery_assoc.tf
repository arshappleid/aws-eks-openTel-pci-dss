
data "aws_route53_zone" "service_discovery" {
  name         = "financeguard.local."
  private_zone = true
}


resource "aws_route53_zone_association" "frontend" {
  zone_id = data.aws_route53_zone.service_discovery.zone_id
  vpc_id  = module.frontend_network.vpc_id
}


resource "aws_route53_zone_association" "backend" {
  zone_id = data.aws_route53_zone.service_discovery.zone_id
  vpc_id  = module.backend_network.vpc_id
}