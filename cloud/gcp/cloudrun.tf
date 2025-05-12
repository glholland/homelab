resource "google_cloud_run_service" "default" {
  name     = "example-cloud-run"
  location = "us-central1"
  project  = var.ty_gcp_project_id

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/${var.ty_gcp_project_id}/dev-registry/angular-hello-world@sha256:16b63ba25ca9a8d3abd9bf5dbb18a7f3ac6d07f82f16f48a760b9564fbc249e8"

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            memory = "512Mi"
            cpu    = "1"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_domain_mapping" "default" {
  location = "us-central1"
  name     = "tylerstefancin.com"
  project  = var.ty_gcp_project_id

  metadata {
    namespace = var.ty_gcp_project_id
  }

  spec {
    route_name = google_cloud_run_service.default.name
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  service  = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  project  = var.ty_gcp_project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "cloud_run_url" {
  value = google_cloud_run_service.default.status[0].url
}
