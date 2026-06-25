data "aws_lb_target_group" "frontend" {
  name = "tg-frontend-${local.environment}"
}

data "aws_lb_target_group" "backend" {
  name = "tg-backend-${local.environment}"
}

data "aws_lb_target_group" "argocd" {
  name = "tg-frontend-${local.environment}-argocd"
}
