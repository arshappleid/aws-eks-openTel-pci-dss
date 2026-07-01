
data "aws_service_discovery_dns_namespace" "internal" {
  name = "financeguard.local"
  type = "DNS_PRIVATE"
}

data "aws_service_discovery_service" "otel_collector" {
  name         = "otel-collector"
  namespace_id = data.aws_service_discovery_dns_namespace.internal.id
}
