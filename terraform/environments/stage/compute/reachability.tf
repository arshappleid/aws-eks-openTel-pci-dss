



data "aws_instances" "backend_nodes" {
  filter {
    name   = "tag:kubernetes.io/cluster/${local.backend_cluster_name}"
    values = ["owned"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "backend_node" {
  count       = length(data.aws_instances.backend_nodes.ids) > 0 ? 1 : 0
  instance_id = data.aws_instances.backend_nodes.ids[0]
}

locals {

  eks_node_eni_id = length(data.aws_instance.backend_node) > 0 ? data.aws_instance.backend_node[0].network_interface_id : ""
}


resource "aws_ec2_network_insights_path" "egress_to_dns" {
  count = local.eks_node_eni_id != "" ? 1 : 0

  source           = local.eks_node_eni_id
  destination      = "igw-07d73976f32aa275b"
  destination_ip   = "8.8.8.8"
  destination_port = 53
  protocol         = "udp"

  tags = {
    Name = "stage-egress-to-8.8.8.8"
  }
}


data "aws_network_interfaces" "alb" {
  filter {
    name   = "description"
    values = ["ELB app/inspection-alb/*"]
  }
}

resource "aws_ec2_network_insights_path" "ingress_from_alb" {
  count = (local.eks_node_eni_id != "" && length(data.aws_network_interfaces.alb.ids) > 0) ? 1 : 0

  source      = data.aws_network_interfaces.alb.ids[0]
  destination = local.eks_node_eni_id
  protocol    = "tcp"

  tags = {
    Name = "stage-ingress-from-alb"
  }
}