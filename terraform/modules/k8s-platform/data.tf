data "aws_lb_target_group" "frontend" {
  name = "tg-frontend-${var.env}"
}

data "aws_lb_target_group" "backend" {
  name = "tg-backend-${var.env}"
}

data "aws_lb_target_group" "argocd" {
  name = "tg-frontend-${var.env}-argocd"
}
