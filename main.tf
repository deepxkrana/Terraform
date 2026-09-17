terraform {
  required_version = ">= 1.7.0"
}

resource "terraform_data" "platform" {
  input = {
    name  = var.environment
    owner = var.owner
  }
}

resource "terraform_data" "service" {
  for_each = var.services

  input = {
    name        = each.key
    environment = var.environment
    port        = each.value.port
    replicas    = each.value.replicas
  }
}

resource "terraform_data" "sensitivity_demo" {
  input = {
    token = var.demo_token
  }
}
moved {
  from = terraform_data.environment
  to   = terraform_data.platform
}
