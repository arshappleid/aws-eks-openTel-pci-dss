output "frontend_cluster_name" {
  description = "The name of the Frontend EKS cluster"
  value       = module.frontend_eks.cluster_name
}

output "frontend_cluster_endpoint" {
  description = "The endpoint for Frontend EKS Kubernetes API"
  value       = module.frontend_eks.cluster_endpoint
}

output "frontend_cluster_arn" {
  description = "The ARN of the Frontend EKS Cluster"
  value       = module.frontend_eks.cluster_arn
}

output "backend_cluster_name" {
  description = "The name of the Backend EKS cluster"
  value       = module.backend_eks.cluster_name
}

output "backend_cluster_endpoint" {
  description = "The endpoint for Backend EKS Kubernetes API"
  value       = module.backend_eks.cluster_endpoint
}

output "backend_cluster_arn" {
  description = "The ARN of the Backend EKS Cluster"
  value       = module.backend_eks.cluster_arn
}