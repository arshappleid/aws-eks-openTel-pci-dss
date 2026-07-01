resource "aws_service_discovery_instance" "bastion_otel" {
  instance_id = aws_instance.bastion.id
  service_id  = data.aws_service_discovery_service.otel_collector.id

  attributes = {
    AWS_INSTANCE_IPV4 = aws_instance.bastion.private_ip
  }
}
