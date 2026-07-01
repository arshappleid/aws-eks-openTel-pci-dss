
resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "financeguard.local"
  description = "Private DNS namespace for FinanceGuard internal services"
  vpc         = module.inspection_vpc.vpc_id
}


resource "aws_service_discovery_service" "otel_collector" {
  name = "otel-collector"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id

    dns_records {
      ttl  = 60
      type = "A"
    }
  }
}
