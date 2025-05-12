# Workload Identity Federation for GitHub Actions
# This enables GitHub Actions workflows to authenticate to Google Cloud
# without requiring service account keys

# Create a workload identity pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.ty_gcp_project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions workflows"
}

# Create a workload identity provider for GitHub Actions within the pool
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.ty_gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC identity provider for GitHub Actions"
  attribute_condition                = "attribute.repository == \"glholland/angular-site\""

  # Configure the attributes from the OIDC tokens that are needed to uniquely identify the GitHub repository
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Use GitHub's OIDC provider
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create a service account for GitHub Actions to impersonate
resource "google_service_account" "github_actions_sa" {
  project      = var.ty_gcp_project_id
  account_id   = "github-actions"
  display_name = "GitHub Actions Service Account"
  description  = "Service account for GitHub Actions workflows"
}

# Allow the GitHub Actions workload identity to impersonate the service account
resource "google_project_iam_member" "github_actions_sa_token_creator" {
  project = var.ty_gcp_project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

resource "google_project_iam_member" "github_actions_sa_artifact_registry" {
  project = var.ty_gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Allow the GitHub Actions workload identity to use the service account (for angular-site repo)
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "principalSet://iam.googleapis.com/projects/392286243478/locations/global/workloadIdentityPools/github-pool/attribute.repository/glholland/angular-site"
}

# Allow the GitHub Actions workload identity to impersonate the service account (for angular-site repo)
resource "google_service_account_iam_member" "workload_identity_sa_user" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/392286243478/locations/global/workloadIdentityPools/github-pool/attribute.repository/glholland/angular-site"
}

# Update this resource name to match what's in your infrastructure
resource "google_project_iam_member" "github_actions_sa_storage_admin" {
  project = var.ty_gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Output values that will be needed in GitHub Actions workflow
output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "The full resource name of the workload identity provider"
}

output "service_account_email" {
  value       = google_service_account.github_actions_sa.email
  description = "The email address of the service account"
}
