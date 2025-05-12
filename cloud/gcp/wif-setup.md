# Workload Identity Federation for GitHub Actions

This document describes how to set up Workload Identity Federation (WIF) for GitHub Actions in Google Cloud Platform. Workload Identity Federation allows GitHub Actions workflows to authenticate to GCP without using service account keys.

## Prerequisites

- Google Cloud Project
- Terraform installed
- GitHub repository

## Configuration Steps

### 1. Enable Required APIs

Ensure the following APIs are enabled in your GCP project:

```terraform
resource "google_project_service" "ty_gcp_services" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "artifactregistry.googleapis.com",
    # Other required APIs
  ])
  project = var.ty_gcp_project_id
  service = each.key
}
```

### 2. Create Workload Identity Pool

```terraform
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.ty_gcp_project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions workflows"
}
```

### 3. Create Workload Identity Provider

```terraform
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.ty_gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC identity provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Restrict to specific repository
  attribute_condition = "attribute.repository == \"glholland/angular-site\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
```

### 4. Create Service Account for GitHub Actions

```terraform
resource "google_service_account" "github_actions_sa" {
  project      = var.ty_gcp_project_id
  account_id   = "github-actions"
  display_name = "GitHub Actions Service Account"
  description  = "Service account for GitHub Actions workflows"
}
```

### 5. Configure IAM Permissions

#### 5.1 Allow GitHub Actions to use the service account

```terraform
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/glholland/angular-site"
}
```

#### 5.2 Allow GitHub Actions to impersonate the service account

```terraform
resource "google_service_account_iam_member" "workload_identity_sa_user" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/glholland/angular-site"
}
```

#### 5.3 Allow the service account to create tokens

```terraform
resource "google_project_iam_member" "github_actions_sa_token_creator" {
  project = var.ty_gcp_project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}
```

### 6. Grant Additional Permissions to the Service Account

Based on your needs, grant the service account appropriate permissions:

```terraform
# Storage Admin permissions
resource "google_project_iam_member" "github_actions_sa_storage_admin" {
  project = var.ty_gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Artifact Registry permissions
resource "google_project_iam_member" "github_actions_sa_artifact_registry" {
  project = var.ty_gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}
```

### 7. Output the Configuration Values

```terraform
output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "The full resource name of the workload identity provider"
}

output "service_account_email" {
  value       = google_service_account.github_actions_sa.email
  description = "The email address of the service account"
}
```

## Using in GitHub Actions

### 1. Add GitHub Secrets

Add these secrets to your GitHub repository:

- `WIF_PROVIDER`: The output value of `workload_identity_provider`
- `SERVICE_ACCOUNT`: The output value of `service_account_email`

### 2. Configure GitHub Actions Workflow

```yaml
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: "read"
      id-token: "write" # Required for requesting the JWT

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.SERVICE_ACCOUNT }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      # If using Artifact Registry for Docker images
      - name: Configure Docker for Artifact Registry
        run: gcloud auth configure-docker us-central1-docker.pkg.dev

      # Additional steps for your workflow
```

## Troubleshooting

### Permission Issues

1. Verify that all required APIs are enabled
2. Check that both `roles/iam.serviceAccountUser` and `roles/iam.workloadIdentityUser` are correctly configured
3. Ensure the repository name in the `attribute_condition` matches the actual GitHub repository
4. Verify that the service account has the `roles/iam.serviceAccountTokenCreator` role

### Authentication Issues

1. Check that the GitHub workflow has `id-token: 'write'` permission
2. Verify that the GitHub secrets for the provider and service account are correct
3. Make sure the attribute condition matches your GitHub repository name exactly

## References

- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions auth](https://github.com/google-github-actions/auth)
- [OIDC configuration for GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)
