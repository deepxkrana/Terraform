variable "project_id" {
  description = "Mock project identifier used only for configuration testing."
  type        = string
  default     = "student-mock-project"
}

variable "region" {
  description = "Region represented by the architecture."
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "Zone represented by the managed instance group."
  type        = string
  default     = "asia-south1-a"
}

variable "environment" {
  description = "Environment included in resource names."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "machine_type" {
  description = "Machine type used by the instance template."
  type        = string
  default     = "e2-micro"

  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium"], var.machine_type)
    error_message = "machine_type must be e2-micro, e2-small, or e2-medium."
  }
}

variable "scaling" {
  description = "Autoscaling boundaries and target CPU utilization."

  type = object({
    min_instances = number
    max_instances = number
    target_cpu    = number
  })

  default = {
    min_instances = 2
    max_instances = 6
    target_cpu    = 0.60
  }

  validation {
    condition = (
      var.scaling.min_instances >= 2 &&
      var.scaling.max_instances <= 10 &&
      var.scaling.max_instances >= var.scaling.min_instances &&
      var.scaling.target_cpu >= 0.40 &&
      var.scaling.target_cpu <= 0.80
    )

    error_message = "Scaling requires min >= 2, max <= 10, max >= min, and target_cpu between 0.40 and 0.80."
  }
}
