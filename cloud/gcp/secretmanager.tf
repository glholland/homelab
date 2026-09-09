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
  secret                 = google_secret_manager_secret.secrets_tfvars.id
  secret_data_wo         = file("secrets.tfvars")
  secret_data_wo_version = 1
  deletion_policy        = "DISABLE"
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
  secret                 = google_secret_manager_secret.proxmox_tfvars.id
  secret_data_wo         = file("../../proxmox/terraform/secrets.tfvars")
  secret_data_wo_version = 1
  deletion_policy        = "DISABLE"
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

resource "google_secret_manager_secret" "zitadel_db_password" {
  secret_id = "zitadel-db-password"
  labels = {
    label = "zitadel"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "zitadel_db_superuser_password" {
  secret_id = "zitadel-db-superuser-password"
  labels = {
    label = "zitadel"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "zitadel_masterkey" {
  secret_id = "zitadel-masterkey"
  labels = {
    label = "zitadel"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "external_dns_pihole_password" {
  secret_id = "external-dns-pihole-password"
  labels = {
    label = "external-dns"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "github_pac_token" {
  secret_id = "github-pac-token"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "github_pac_webhook_secret" {
  secret_id = "github-pac-webhook-secret"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "cloudflared_pac_tunnel_token" {
  secret_id = "cloudflared-pac-tunnel-token"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "harbor_ci_robot_username" {
  secret_id = "harbor-ci-robot-username"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "harbor_ci_robot_password" {
  secret_id = "harbor-ci-robot-password"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

## Pipelines-as-Code GitHub App
#
# Replaces the webhook+PAT provider so PAC can use the Checks API
# (GitHub only allows Check Runs to be created by a GitHub App, not a
# personal access token). This is controller-wide, not per-Repository --
# consumed via the fixed `pipelines-as-code-secret` name the PAC
# controller expects (PAC_CONTROLLER_SECRET env var).

resource "google_secret_manager_secret" "github_pac_app_id" {
  secret_id = "github-pac-app-id"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "github_pac_app_private_key" {
  secret_id = "github-pac-app-private-key"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "github_pac_app_webhook_secret" {
  secret_id = "github-pac-app-webhook-secret"
  labels = {
    label = "tekton"
  }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "google_oauth_client_id" {
  secret_id = "google-oauth-client-id"
  labels = {
    label = "oidc"
  }
  replication {
    auto {}
  }
}
