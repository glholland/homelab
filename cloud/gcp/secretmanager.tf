resource "google_secret_manager_secret" "secrets_tfvars" {
  secret_id = "secrets_tfvars"
  labels = {
    label = "terraform"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secrets_tfvars" {
  secret          = google_secret_manager_secret.secrets_tfvars.id
  secret_data_wo  = file("secrets.tfvars")
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
  secret_data_wo  = file("../../proxmox/terraform/secrets.tfvars")
  deletion_policy = "DISABLE"
}

resource "google_secret_manager_secret" "google_oidc_client_id" {
  secret_id = "google_oidc_client_id"
  labels = {
    label = "oidc"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "google_oidc_client_secret" {
  secret_id = "google_oidc_client_secret"
  labels = {
    label = "oidc"
  }
  replication {
    auto {}
  }
}

## OKD cluster credentials
#
# Values are populated out of band (gcloud secrets versions add) rather than
# from files on disk, so that no credential material lives in this repo or in
# Terraform state. Terraform owns the secret containers only.

resource "google_secret_manager_secret" "okd_kubeconfig" {
  secret_id = "okd_kubeconfig"
  labels = {
    label = "okd"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "okd_install_config" {
  secret_id = "okd_install_config"
  labels = {
    label = "okd"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "alertmanager_discord_webhook" {
  secret_id = "alertmanager_discord_webhook"
  labels = {
    label = "alerting"
  }
  replication {
    auto {}
  }
}

## Application secrets referenced by argocd-vault-plugin placeholders
#
# Each is referenced from a manifest under kubernetes/ as
# <path:projects/812524172865/secrets/NAME#NAME>.

resource "google_secret_manager_secret" "radarr_api_key" {
  secret_id = "radarr-api-key"
  labels = {
    label = "media"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "sonarr_api_key" {
  secret_id = "sonarr-api-key"
  labels = {
    label = "media"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "pterodactyl_mariadb_root_password" {
  secret_id = "pterodactyl-mariadb-root-password"
  labels = {
    label = "pterodactyl"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "pterodactyl_db_password" {
  secret_id = "pterodactyl-db-password"
  labels = {
    label = "pterodactyl"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "pterodactyl_app_key" {
  secret_id = "pterodactyl-app-key"
  labels = {
    label = "pterodactyl"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "open_webui_secret_key" {
  secret_id = "open-webui-secret-key"
  labels = {
    label = "open-webui"
  }
  replication {
    auto {}
  }
}
