output "argocd_webhook_secret_frontend" {
  value     = random_password.argocd_webhook_secret_frontend.result
  sensitive = true
}

output "argocd_webhook_secret_backend" {
  value     = random_password.argocd_webhook_secret_backend.result
  sensitive = true
}
