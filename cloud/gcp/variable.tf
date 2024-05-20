variable "gcp_project_id" {
	description = "Project ID for Homelab GCP project"
	type = string
	sensitive = true
}

variable "gcp_account" {
	description = "Gmail acct used for GCP"
	type = string
	sensitive = true
}

variable "gcp_service_list" {
  description ="The list of apis necessary"
  type = list(string)
  default = [
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
		"secretmanager.googleapis.com",
		"cloudbilling.googleapis.com",
		"storage-api.googleapis.com"
  ]
}
