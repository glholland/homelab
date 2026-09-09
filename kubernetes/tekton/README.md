# Tekton (OpenShift Pipelines)

Installs Tekton via the `okd-pipelines-operator` package on the `okderators` CatalogSource, with Pipelines-as-Code (PAC) enabled for GitHub-webhook-triggered CI/CD against this repo. Replaces an earlier abandoned attempt at installing vanilla upstream Tekton directly from `tekton-releases`' release YAML.

## Layout

```text
tekton/
├── base/
│   └── subscription.yaml          # OLM Subscription, cluster-scoped (openshift-operators)
├── components/
│   ├── pipelines-as-code/         # tekton-ci namespace, PAC Repository CR, secrets, harbor-push SA
│   └── cloudflare-tunnel/         # cloudflared Deployment exposing the PAC controller publicly
└── overlays/
    └── okd/
        └── tekton-config.yaml     # TektonConfig singleton, profile: all
```

## Install

```bash
oc apply -k kubernetes/tekton/overlays/okd
```

The Subscription is pinned to `channel: alpha` / `startingCSV: okd-pipelines-operator.v1.7.0-2025-02-11-151011` -- confirmed against the live `okderators` PackageManifest, which only publishes that one channel. Re-check with `oc get packagemanifest okd-pipelines-operator -n openshift-marketplace -o yaml` if the catalog image gets bumped later.

## OKD Specifics

- `okd-pipelines-operator` is subscribed into `openshift-operators` (cluster-scoped) rather than a dedicated namespace, reusing OLM's default global `OperatorGroup` -- no `OperatorGroup` manifest here, unlike the namespace-scoped cert-manager/rook-ceph installs elsewhere in this repo. Confirmed live: `AllNamespaces` is the only install mode this package supports.
- The `TektonConfig` reconciler auto-provisions a `pipeline` ServiceAccount with an appropriate SCC binding in every namespace it manages -- this repo does not grant any SCC manually for Tekton. Confirm after first deploy with `oc get sa pipeline -n tekton-ci` / `oc get rolebinding -n tekton-ci` before assuming otherwise.

## Public Reachability: Cloudflare Tunnel, not a Route

GitHub needs to reach the PAC controller over the public internet. Nothing else in this repo is exposed publicly (external-dns only publishes into internal Pi-hole DNS), and rather than port-forwarding the Ubiquiti router to the OKD ingress, `components/cloudflare-tunnel/` runs `cloudflared` in-cluster with an outbound-only connection to Cloudflare's edge -- no inbound port ever opens on the home network. It talks directly to the `pipelines-as-code-controller` Service in `openshift-pipelines` over cluster-internal DNS (see `configmap.yaml`), so this doesn't depend on or use the Route that OpenShift Pipelines otherwise auto-creates for that controller.

## Manual Steps

None of this is expressible as a manifest -- do these by hand:

1. **GitHub PAT + webhook secret**: create a GitHub personal access token (repo scope) for `glholland/homelab`, and pick a webhook secret value. Populate:
   ```bash
   gcloud secrets versions add github-pac-token --data-file=- <<< "<token>"
   gcloud secrets versions add github-pac-webhook-secret --data-file=- <<< "<secret>"
   ```
2. **Harbor robot account**: in the Harbor UI, create a robot account scoped to the `library` project with push+pull permission. Populate:
   ```bash
   gcloud secrets versions add harbor-ci-robot-username --data-file=- <<< "<robot username>"
   gcloud secrets versions add harbor-ci-robot-password --data-file=- <<< "<robot token>"
   ```
3. **Cloudflare Tunnel**: in the Cloudflare Zero Trust dashboard (Networks > Tunnels > Create a tunnel > Cloudflared), create a tunnel and copy its token -- this is a "remotely-managed" tunnel for auth purposes only; the actual ingress routing rule lives in `configmap.yaml`, not the dashboard. Populate:
   ```bash
   gcloud secrets versions add cloudflared-pac-tunnel-token --data-file=- <<< "<tunnel token>"
   ```
   Then add a DNS record for `pac.garrettholland.com` (or whatever hostname `configmap.yaml` uses) as a CNAME to `<tunnel-id>.cfargotunnel.com` in the Cloudflare dashboard for the `garrettholland.com` zone.
4. Register the webhook (`https://pac.garrettholland.com`, plus the secret from step 1) on the `glholland/homelab` GitHub repo's Settings > Webhooks.

## Pipelines

Actual `PipelineRun` definitions live at the repo root under [`.tekton/`](../../.tekton/), not here -- Pipelines-as-Code discovers them there automatically once the `Repository` CR and webhook are live:
- `build-and-push.yaml` -- builds and pushes images under `images/**` to Harbor on push to `main`.
- `ci-checks.yaml` -- runs `kustomize build` + `yamllint` against `kubernetes/` and `okd/` on every PR.

**Known gap**: `build-and-push.yaml` hardcodes `image-name: steam-cmd` since Tekton has no built-in "which subdirectory under `images/` changed" param. Fix before adding a second image under `images/` -- either a small script step parsing PAC's `{{ files_changed_added_or_modified }}`, or split into one PipelineRun per image.

**ArgoCD boundary**: `build-and-push` stops at "image pushed to Harbor" and never runs `oc apply`/`kubectl apply` against cluster manifests. ArgoCD isn't deployed yet; keeping this pipeline's blast radius to build-and-push only (no cluster-apply RBAC on `harbor-push`) means it doesn't need reworking once ArgoCD exists and takes over as the thing that actually applies manifests.

## Testing

```bash
# Operator installed and healthy
oc get csv -n openshift-operators | grep -i pipelines

# TektonConfig reconciled
oc get tektonconfig config -o jsonpath='{.status.conditions}'

# After the webhook is live: push a trivial commit touching images/steam-cmd/Dockerfile
tkn pipelinerun list -n tekton-ci

# Open a throwaway PR against this repo and confirm ci-checks reports a GitHub Check
```
