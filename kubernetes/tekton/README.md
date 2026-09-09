# Tekton (OpenShift Pipelines)

Installs Tekton via the `okd-pipelines-operator` package on the `okderators` CatalogSource, with Pipelines-as-Code (PAC) enabled for GitHub-webhook-triggered CI/CD against this repo.

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

Subscription is pinned to `channel: alpha` / `startingCSV: okd-pipelines-operator.v1.7.0-2025-02-11-151011`. Re-check with `oc get packagemanifest okd-pipelines-operator -n openshift-marketplace -o yaml` if the catalog image gets bumped.

## OKD Specifics

- Subscribed into `openshift-operators` (cluster-scoped, `AllNamespaces`-only) -- no `OperatorGroup` needed here.
- `TektonConfig` auto-provisions a `pipeline` ServiceAccount + SCC binding per namespace. No manual SCC in this repo. Verify: `oc get sa pipeline -n tekton-ci`.

## Public Reachability: Cloudflare Tunnel

`components/cloudflare-tunnel/` runs `cloudflared` in-cluster (outbound-only to Cloudflare's edge, no inbound port) and routes straight to the `pipelines-as-code-controller` Service over cluster-internal DNS. Ingress routing lives in `configmap.yaml`, not the Cloudflare dashboard.

## Manual Steps

1. **GitHub PAT + webhook secret**: fine-grained token on `glholland/homelab` -- Contents (read), Pull requests (read/write), Commit statuses (read/write), Metadata (read). Pick a webhook secret value too.
   ```bash
   gcloud secrets versions add github-pac-token --data-file=- <<< "<token>"
   gcloud secrets versions add github-pac-webhook-secret --data-file=- <<< "<secret>"
   ```
2. **Harbor robot account**: Harbor UI, scoped to the `library` project, push+pull.
   ```bash
   gcloud secrets versions add harbor-ci-robot-username --data-file=- <<< "<robot username>"
   gcloud secrets versions add harbor-ci-robot-password --data-file=- <<< "<robot token>"
   ```
3. **Cloudflare Tunnel**: Zero Trust dashboard > Networks > Tunnels > Create a tunnel > Cloudflared.
   ```bash
   gcloud secrets versions add cloudflared-pac-tunnel-token --data-file=- <<< "<tunnel token>"
   ```
   Add a CNAME for `pac.garrettholland.com` to `<tunnel-id>.cfargotunnel.com` in the `garrettholland.com` zone.
4. Register the webhook (`https://pac.garrettholland.com` + the secret from step 1) on the repo's Settings > Webhooks.

## Pipelines

`PipelineRun` definitions live at [`.tekton/`](../../.tekton/) (repo root), not here:
- `build-and-push.yaml` -- Harbor image builds on push to `main`, scoped to `images/**`.
- `ci-checks.yaml` -- `kustomize build` + `yamllint` on PRs.

Notes:
- Reporting is via PR comments / commit statuses, not the Checks tab -- that API isn't available to webhook+PAT-based PAC.
- `build-and-push.yaml` hardcodes `image-name: steam-cmd` -- fix before a second image lands under `images/`.
- `build-and-push` stops at "image pushed" and never applies cluster manifests, so it won't need rework once ArgoCD exists.
- `git-clone`/`buildah` are fetched via Tekton's native `resolver: hub` (pinned to versions 0.10.0 / 0.9.0), **not** the `pipelinesascode.tekton.dev/task` annotation. That annotation resolves through PAC's own `hub-url` setting, which on this operator version still defaults to the decommissioned `api.hub.tekton.dev` and silently fails at runtime. The native hub-resolver's own config (`hubresolver-config` in `openshift-pipelines`) already points at Artifact Hub correctly, which is why it's used instead. Verified with a throwaway `TaskRun` before relying on it.

## Testing

```bash
oc get csv -n openshift-operators | grep -i pipelines
oc get tektonconfig config -o jsonpath='{.status.conditions}'

# after the webhook is live
tkn pipelinerun list -n tekton-ci
# push a commit touching images/steam-cmd/Dockerfile, or open a throwaway PR
```
