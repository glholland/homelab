resource "google_artifact_registry_repository" "registry" {
  provider      = google-beta
  project       = var.ty_gcp_project_id
  repository_id = "dev-registry"
  location      = var.gcp_region
  format        = "DOCKER"
  description   = "Registry for container images"
}

# Grant the Cloud Run service account access to the Artifact Registry
resource "google_artifact_registry_repository_iam_member" "cloudrun_registry_reader" {
  project    = var.ty_gcp_project_id
  location   = var.gcp_region
  repository = google_artifact_registry_repository.registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-812524172865@serverless-robot-prod.iam.gserviceaccount.com"

  depends_on = [google_artifact_registry_repository.registry]
}
