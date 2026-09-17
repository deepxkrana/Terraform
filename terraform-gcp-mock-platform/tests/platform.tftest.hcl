mock_provider "google" {}

run "development_platform" {
  command = plan

  variables {
    project_id   = "student-mock-project"
    region       = "asia-south1"
    zone         = "asia-south1-a"
    environment  = "dev"
    machine_type = "e2-micro"

    scaling = {
      min_instances = 2
      max_instances = 6
      target_cpu    = 0.60
    }
  }

  assert {
    condition     = google_compute_network.main.auto_create_subnetworks == false
    error_message = "The VPC must use custom subnet mode."
  }

  assert {
    condition     = google_compute_subnetwork.web.private_ip_google_access == true
    error_message = "Private Google Access must be enabled on the web subnet."
  }

  assert {
    condition     = google_compute_instance_template.web.machine_type == "e2-micro"
    error_message = "The development instance template must use e2-micro."
  }

  assert {
    condition     = length(google_compute_instance_template.web.network_interface[0].access_config) == 0
    error_message = "Web instances must not receive an external IP address."
  }

  assert {
    condition     = google_compute_instance_group_manager.web.target_size == 2
    error_message = "The managed instance group must start at the minimum size."
  }

  assert {
    condition     = google_compute_autoscaler.web.autoscaling_policy[0].min_replicas == 2
    error_message = "The autoscaler minimum must be two instances."
  }

  assert {
    condition     = google_compute_autoscaler.web.autoscaling_policy[0].max_replicas == 6
    error_message = "The autoscaler maximum must be six instances."
  }

  assert {
    condition     = google_compute_autoscaler.web.autoscaling_policy[0].cpu_utilization[0].target == 0.60
    error_message = "The autoscaler CPU target must be 60 percent."
  }

  assert {
    condition     = google_compute_health_check.web.http_health_check[0].request_path == "/health"
    error_message = "The load balancer must check the /health path."
  }

  assert {
    condition     = toset(google_compute_firewall.allow_health_checks.source_ranges) == toset(["35.191.0.0/16", "130.211.0.0/22"])
    error_message = "The firewall must use the documented health-check source ranges."
  }

  assert {
    condition     = google_storage_bucket.assets.public_access_prevention == "enforced"
    error_message = "Public access prevention must be enforced."
  }

  assert {
    condition     = google_storage_bucket.assets.versioning[0].enabled == true
    error_message = "Object versioning must be enabled."
  }

  assert {
    condition     = google_storage_bucket_iam_member.web_asset_reader.role == "roles/storage.objectViewer"
    error_message = "The web service account must receive only object-viewer access."
  }
}
run "production_platform" {
  command = plan

  variables {
    environment  = "prod"
    machine_type = "e2-medium"

    scaling = {
      min_instances = 3
      max_instances = 10
      target_cpu    = 0.55
    }
  }

  assert {
    condition     = startswith(google_compute_network.main.name, "prod-")
    error_message = "Production resource names must start with prod-."
  }

  assert {
    condition     = google_compute_instance_template.web.machine_type == "e2-medium"
    error_message = "The production test must use e2-medium."
  }

  assert {
    condition     = google_compute_autoscaler.web.autoscaling_policy[0].max_replicas == 10
    error_message = "The production test must permit up to ten instances."
  }
}
run "reject_invalid_scaling_order" {
  command = plan

  variables {
    scaling = {
      min_instances = 6
      max_instances = 3
      target_cpu    = 0.60
    }
  }

  expect_failures = [var.scaling]
}
run "reject_unsafe_cpu_target" {
  command = plan

  variables {
    scaling = {
      min_instances = 2
      max_instances = 6
      target_cpu    = 0.95
    }
  }

  expect_failures = [var.scaling]
}
run "reject_unapproved_machine_type" {
  command = plan

  variables {
    machine_type = "n2-standard-32"
  }

  expect_failures = [var.machine_type]
}
