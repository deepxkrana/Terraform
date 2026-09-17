provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  prefix = "${var.environment}-college-portal"

  common_labels = {
    environment = var.environment
    application = "college-portal"
    managed_by  = "terraform"
  }
}

resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "web" {
  project                  = var.project_id
  name                     = "${local.prefix}-web-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.20.1.0/24"
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_health_checks" {
  project = var.project_id
  name    = "${local.prefix}-allow-health-checks"
  network = google_compute_network.main.name

  direction     = "INGRESS"
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["web-backend"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}
resource "google_service_account" "web" {
  project      = var.project_id
  account_id   = "${var.environment}-portal-web"
  display_name = "${var.environment} college portal web service"
}
resource "google_compute_instance_template" "web" {
  project      = var.project_id
  name_prefix  = "${local.prefix}-template-"
  machine_type = var.machine_type
  region       = var.region
  tags         = ["web-backend"]
  labels       = local.common_labels

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.web.id
  }

  service_account {
    email  = google_service_account.web.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "healthy" > /var/www/html/health
    systemctl enable --now nginx
  EOT

  lifecycle {
    create_before_destroy = true
  }
}
resource "google_compute_instance_group_manager" "web" {
  project            = var.project_id
  name               = "${local.prefix}-mig"
  base_instance_name = "${local.prefix}-web"
  zone               = var.zone
  target_size        = var.scaling.min_instances

  version {
    instance_template = google_compute_instance_template.web.id
  }

  named_port {
    name = "http"
    port = 80
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    max_surge_fixed                = 1
    max_unavailable_fixed          = 0
    replacement_method             = "SUBSTITUTE"
    most_disruptive_allowed_action = "REPLACE"
  }
}
resource "google_compute_autoscaler" "web" {
  project = var.project_id
  name    = "${local.prefix}-autoscaler"
  zone    = var.zone
  target  = google_compute_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = var.scaling.min_instances
    max_replicas    = var.scaling.max_instances
    cooldown_period = 60

    cpu_utilization {
      target = var.scaling.target_cpu
    }
  }
}
resource "google_compute_health_check" "web" {
  project             = var.project_id
  name                = "${local.prefix}-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}
resource "google_compute_backend_service" "web" {
  project               = var.project_id
  name                  = "${local.prefix}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.web.id]

  backend {
    group           = google_compute_instance_group_manager.web.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.80
  }
}
resource "google_compute_url_map" "web" {
  project         = var.project_id
  name            = "${local.prefix}-url-map"
  default_service = google_compute_backend_service.web.id
}
resource "google_compute_target_http_proxy" "web" {
  project = var.project_id
  name    = "${local.prefix}-http-proxy"
  url_map = google_compute_url_map.web.id
}
resource "google_compute_global_address" "web" {
  project = var.project_id
  name    = "${local.prefix}-ip"
}
resource "google_compute_global_forwarding_rule" "web" {
  project               = var.project_id
  name                  = "${local.prefix}-forwarding-rule"
  ip_address            = google_compute_global_address.web.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.web.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
resource "google_storage_bucket" "assets" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.environment}-portal-assets"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.common_labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age            = 30
      with_state     = "ARCHIVED"
      matches_prefix = ["temporary/"]
    }

    action {
      type = "Delete"
    }
  }
}
resource "google_storage_bucket_iam_member" "web_asset_reader" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.web.email}"
}

