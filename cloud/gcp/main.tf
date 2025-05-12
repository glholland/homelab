provider "google" {
  user_project_override = true
  billing_project       = var.gcp_project_id
  project               = var.gcp_project_id
}

terraform {
  backend "gcs" {
    bucket = "homelab-tfstate-26300"
    prefix = "terraform/state"
  }
}

resource "google_project" "homelab" {
  name            = "Home"
  project_id      = var.gcp_project_id
  billing_account = data.google_billing_account.account.id
}

resource "google_project" "ty_project" {
  name            = "ty-poc"
  project_id      = var.ty_gcp_project_id
  billing_account = data.google_billing_account.account.id

}

# Bootstrap serviceusage API
# https://medium.com/rockedscience/how-to-fully-automate-the-deployment-of-google-cloud-platform-projects-with-terraform-16c33f1fb31f
resource "null_resource" "enable_service_usage_api" {
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com --project ${var.gcp_project_id}"
  }

  depends_on = [google_project.homelab]
}

resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  project  = var.gcp_project_id
  service  = each.key
}

resource "google_project_service" "ty_gcp_services" {
  for_each = toset(var.ty_gcp_service_list)
  project  = var.ty_gcp_project_id
  service  = each.key
}
