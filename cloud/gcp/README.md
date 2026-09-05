# GCP Terraform

Project: `home-26300` (project number `812524172865`)

## Usage

Make CLI identity available to TF

```bash
gcloud auth application-default login
```

Login & seed secrets

```bash
gcloud auth login
gcloud secrets versions access 1 --secret=secrets_tfvars --out-file=secrets.tfvars
```

Apply TF!

### Quota project

The GCS state backend and any ADC-based client bill against the *quota project*. If
it points at a project whose billing account is closed, every GCS/ADC call fails with
`403 UserProjectAccountProblem` even though `home-26300` itself is fine:

```bash
gcloud config set billing/quota_project home-26300
gcloud auth application-default set-quota-project home-26300
```

## Secret Manager

Secrets live in Secret Manager rather than in this repo. Manifests reference them with
`<path:projects/812524172865/secrets/NAME#KEY>` placeholders — see
`kubernetes/certman/components/cloudflare/cluster-issuer.yaml`.

Retrieve a value:

```bash
gcloud secrets versions access latest --secret=NAME --project=home-26300
```

Write to a file instead of stdout (use for kubeconfig / install-config):

```bash
gcloud secrets versions access latest --secret=okd_kubeconfig \
  --project=home-26300 --out-file=kubeconfig
```

### Inventory

| Secret | Contents | Used by |
| :--- | :--- | :--- |
| `okd_kubeconfig` | Cluster-admin kubeconfig from the agent-based installer | `oc`/`kubectl` access to the OKD cluster |
| `kubeadmin` | `kubeadmin` console password (v2 = current Dec 2025 install; v1 = prior) | OKD web console login |
| `okd_install_config` | `install-config.yaml` backup — includes pull secret and SSH key | Re-running the agent-based installer |
| `alertmanager_discord_webhook` | Discord webhook URL for critical alerts | `okd/okd-agent-based-install/alertmanager.yaml` |
| `cf_email`, `cf_token` | Cloudflare API credentials | cert-manager DNS-01 (`kubernetes/certman/`) |
| `google_oidc_client_id`, `google_oidc_client_secret` | Google OIDC application credentials | OKD OAuth identity provider |
| `oauth_client_secret` | OAuth client secret | OKD OAuth |
| `truenas-*` | TrueNAS API key, username, iSCSI/NFS SSH keys | `kubernetes/democratic-csi/` |
| `secrets_tfvars`, `proxmox_tfvars` | Terraform variable files | `cloud/gcp/`, `proxmox/terraform/` |
| `congress_api_key`, `gemini_key` | Third-party API keys | Application workloads |

Installer output under `okd/okd-agent-based-install/` (`auth/`, `*.log`,
`.openshift_install*`, `rendezvousIP`, `*.iso`, `*.bak`) is gitignored — those files
contain cluster-admin credentials and must never be committed. The credential values
were migrated into the secrets above; pull them back down on demand rather than
keeping copies on disk.

`.openshift_install_state.json` is the exception: it also holds pull-secret and SSH
key material, but at ~540KB it exceeds the 64KB Secret Manager version limit (172KB
even gzipped), and `openshift-install` needs it locally for cluster lifecycle
operations. It stays on disk, gitignored.

> **Note:** `secretmanager.tf` uses the `secret_data_wo` write-only argument, which
> requires google provider >= 6.x. `.terraform.lock.hcl` currently pins 5.29.1 and
> there is no `required_providers` block, so `terraform plan` fails against this
> config. Secrets created outside Terraform are not in state.
