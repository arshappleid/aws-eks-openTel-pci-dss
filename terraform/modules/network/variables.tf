variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones to deploy subnets in"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "intra_subnets" {
  description = "List of subnet CIDR blocks for Intra Subnets (e.g., for TGW attachments, completely isolated from public access)"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all private subnets"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster for tagging subnets"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
variable "env" {
  description = "Environment name"
  type        = string
}

variable "transit_gateway_id" {
  description = "The ID of the Transit Gateway. If provided, a VPC attachment will be created."
  type        = string
  default     = null
}

variable "transit_gateway_route_table_association_id" {
  description = "The ID of the TGW route table to associate the VPC attachment with."
  type        = string
  default     = null
}

variable "transit_gateway_route_table_propagation_id" {
  description = "The ID of the TGW route table to propagate the VPC CIDR to."
  type        = string
  default     = null
}

variable "tgw_destinations" {
  description = "List of destination CIDR blocks to route to the Transit Gateway from the VPC route tables."
  type        = list(string)
  default     = []
}