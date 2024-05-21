resource "google_secret_manager_secret" "secrets_tfvars" {
  secret_id = "secrets_tfvars"

  labels = {
    label = "terraform"
  }

  replication {
    user_managed {
      replicas {
        location = "us-central1"
			}
    }
  }
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

resource "google_secret_manager_secret_version" "secret-version-basic" {
  secret = google_secret_manager_secret.proxmox_tfvars.id
  secret_data = file("../../proxmox/terraform/secrets.tfvars")
  deletion_policy = "DISABLE"
  }
