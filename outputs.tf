output "environment_record" {
  description = "Environment information recorded in state."
  value       = terraform_data.platform.output
}

output "service_records" {
  description = "Service information recorded in state."
  value = {
    for name, service in terraform_data.service :
    name => service.output
  }
}

output "demonstration_token" {
  description = "Redacted CLI output used to discuss sensitive state."
  value       = terraform_data.sensitivity_demo.output.token
  sensitive   = true
}
