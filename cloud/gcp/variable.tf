variable "gcp_project_id" {
  description = "Project ID for Homelab GCP project"
  type        = string
  sensitive   = true
}

variable "gcp_account" {
  description = "Gmail acct used for GCP"
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  description = "The GCP region where resources will be created"
  type        = string
  default     = "us-central1" # Replace with your desired default region
}

variable "gcp_service_list" {
  description = "The list of apis necessary"
  type        = list(string)
  default = [
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "storage-api.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "apikeys.googleapis.com",
    "firebase.googleapis.com",
  ]
}

variable "ty_gcp_project_id" {
  description = "Project ID for Ty's GCP project"
  type        = string
  sensitive   = true
}

variable "ty_gcp_service_list" {
  description = "The list of apis necessary"
  type        = list(string)
  default = [
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "storage-api.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    "apikeys.googleapis.com",

  ]
}
