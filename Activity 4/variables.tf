variable "environment" {
  description = "Training environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "owner" {
  description = "Person or team responsible for the environment."
  type        = string
  default     = "student"
}

variable "services" {
  description = "Services represented in local Terraform state."

  type = map(object({
    port     = number
    replicas = number
  }))

  default = {
    web = {
      port     = 80
      replicas = 2
    }

    worker = {
      port     = 9000
      replicas = 1
    }
  }
}

variable "demo_token" {
  description = "Fictional value used only to demonstrate state sensitivity."
  type        = string
  sensitive   = true
  default     = "training-placeholder-not-a-secret"
}
