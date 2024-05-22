resource "google_secret_manager_secret" "secrets_tfvars" {
  secret_id = "secrets_tfvars"
  labels    = {
    label = "terraform"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secrets_tfvars" {
  secret          = google_secret_manager_secret.secrets_tfvars.id
  secret_data     = file("secrets.tfvars")
  deletion_policy = "DISABLE"
}

## Proxmox

resource "google_secret_manager_secret" "proxmox_tfvars" {
  secret_id = "proxmox_tfvars"
  labels = {
    label = "proxmox"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "proxmox_tfvars" {
  secret          = google_secret_manager_secret.proxmox_tfvars.id
  secret_data     = file("../../proxmox/terraform/secrets.tfvars")
  deletion_policy = "DISABLE"
}
