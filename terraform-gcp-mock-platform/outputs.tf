output "network_name" {
  description = "Name of the planned VPC."
  value       = google_compute_network.main.name
}

output "instance_group_name" {
  description = "Name of the planned managed instance group."
  value       = google_compute_instance_group_manager.web.name
}

output "autoscaling_range" {
  description = "Minimum and maximum planned instance counts."
  value = {
    minimum = google_compute_autoscaler.web.autoscaling_policy[0].min_replicas
    maximum = google_compute_autoscaler.web.autoscaling_policy[0].max_replicas
  }
}

output "health_check_path" {
  description = "HTTP path checked by the load balancer."
  value       = google_compute_health_check.web.http_health_check[0].request_path
}

output "assets_bucket_name" {
  description = "Name of the planned private assets bucket."
  value       = google_storage_bucket.assets.name
}

output "load_balancer_ip" {
  description = "Mock-generated load balancer IP during tests."
  value       = google_compute_global_address.web.address
}
