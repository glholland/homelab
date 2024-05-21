
# Bucket for storing state files
resource "google_storage_bucket" "homelab_tfstate" {
  project       = var.gcp_project_id
  name          = "homelab-tfstate-26300"
  location      = "US-CENTRAL1"
  force_destroy = false
  autoclass {
    enabled = true
  }
  versioning {
    enabled = true
  }
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

resource "google_storage_bucket" "proxmox_tfstate" {
  project       = var.gcp_project_id
  name          = "proxmox-tfstate-26300"
  location      = "US-CENTRAL1"
  force_destroy = false
  autoclass {
    enabled = true
  }
  versioning {
    enabled = true
  }
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}
