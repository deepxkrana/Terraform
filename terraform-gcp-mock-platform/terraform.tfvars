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
