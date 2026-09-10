# Workload Identity Federation for ArgoCD's argocd-vault-plugin sidecar --
# no downloaded key. Lives in the homelab project, not wif.tf's Ty project.
#
# OKD's real issuer is the internal-only https://kubernetes.default.svc, and
# GCP requires issuer_uri to match it exactly, so dynamic discovery (and any
# tunnel) is impossible -- jwks_json is static instead, the one mechanism
# that skips fetching from issuer_uri. components/wif-refresher/ keeps that
# snapshot from going stale, authenticating via this same WIF setup under
# its own identity. `lifecycle.ignore_changes` hands ownership of the oidc
# block to that CronJob. Re-seed okd-jwks-seed.json only if this provider is
# ever destroyed and recreated (`oc get --raw /openid/v1/jwks`).

resource "google_iam_workload_identity_pool" "okd_cluster" {
  project                   = var.gcp_project_id
  workload_identity_pool_id = "okd-cluster-pool"
  display_name              = "OKD Cluster Pool"
  description               = "Identity pool for workloads running on the homelab OKD cluster"
}

resource "google_iam_workload_identity_pool_provider" "okd_cluster" {
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.okd_cluster.workload_identity_pool_id
  workload_identity_pool_provider_id = "okd-cluster-provider"
  display_name                       = "OKD Cluster Provider"
  description                        = "Trusts ServiceAccount tokens issued by the homelab OKD cluster"

  # Only these two identities may authenticate as this provider.
  attribute_condition = "assertion.sub in [\"system:serviceaccount:openshift-gitops:argocd-repo-server-avp\", \"system:serviceaccount:openshift-gitops:argocd-wif-refresher\"]"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  oidc {
    issuer_uri = "https://kubernetes.default.svc"
    jwks_json  = file("${path.module}/okd-jwks-seed.json")
  }

  lifecycle {
    ignore_changes = [oidc]
  }
}

resource "google_service_account" "argocd_avp" {
  project      = var.gcp_project_id
  account_id   = "argocd-avp"
  display_name = "ArgoCD argocd-vault-plugin"
  description  = "Used by ArgoCD's repo-server CMP sidecar to resolve GSM-backed manifest placeholders"
}

resource "google_project_iam_member" "argocd_avp_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.argocd_avp.email}"
}

resource "google_service_account_iam_member" "argocd_avp_workload_identity_user" {
  service_account_id = google_service_account.argocd_avp.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principal://iam.googleapis.com/projects/812524172865/locations/global/workloadIdentityPools/okd-cluster-pool/subject/system:serviceaccount:openshift-gitops:argocd-repo-server-avp"
}

resource "google_service_account" "argocd_wif_refresher" {
  project      = var.gcp_project_id
  account_id   = "argocd-wif-refresher"
  display_name = "ArgoCD WIF JWKS refresher"
  description  = "Keeps okd-cluster-provider's jwks_json in sync with OKD's live signing keys"
}

# Scoped to just this one pool, not project-wide.
resource "google_iam_workload_identity_pool_iam_member" "argocd_wif_refresher_pool_admin" {
  workload_identity_pool_id = google_iam_workload_identity_pool.okd_cluster.name
  role                       = "roles/iam.workloadIdentityPoolAdmin"
  member                     = "serviceAccount:${google_service_account.argocd_wif_refresher.email}"
}

resource "google_service_account_iam_member" "argocd_wif_refresher_workload_identity_user" {
  service_account_id = google_service_account.argocd_wif_refresher.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principal://iam.googleapis.com/projects/812524172865/locations/global/workloadIdentityPools/okd-cluster-pool/subject/system:serviceaccount:openshift-gitops:argocd-wif-refresher"
}

output "argocd_avp_workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.okd_cluster.name
  description = "The full resource name of the OKD cluster workload identity provider -- also the audience the repo-server sidecar's and refresher's projected ServiceAccount tokens must request"
}
