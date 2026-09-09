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

1. **Harbor robot account**: Harbor UI, scoped to the `library` project, push+pull.
   ```bash
   gcloud secrets versions add harbor-ci-robot-username --data-file=- <<< "<robot username>"
   gcloud secrets versions add harbor-ci-robot-password --data-file=- <<< "<robot token>"
   ```
2. **Cloudflare Tunnel**: Zero Trust dashboard > Networks > Tunnels > Create a tunnel > Cloudflared.
   ```bash
   gcloud secrets versions add cloudflared-pac-tunnel-token --data-file=- <<< "<tunnel token>"
   ```
   Add a CNAME for `pac.garrettholland.com` to `<tunnel-id>.cfargotunnel.com` in the `garrettholland.com` zone.
3. **GitHub App**: register an App at github.com/settings/apps/new, permissions Checks (read/write), Contents (read), Issues (read/write), Metadata (read), Pull requests (read/write); subscribe to Check run, Check suite, Issue comment, Pull request, Push; webhook URL `https://pac.garrettholland.com`; generate a private key; install on `glholland/homelab` only.
   ```bash
   gcloud secrets versions add github-pac-app-id --data-file=- <<< "<app id>"
   gcloud secrets versions add github-pac-app-private-key --data-file=<path-to-downloaded-private-key.pem>
   gcloud secrets versions add github-pac-app-webhook-secret --data-file=- <<< "<app webhook secret>"
   ```
   This lands in `pipelines-as-code-secret` in `openshift-pipelines` -- the fixed name/namespace the PAC controller expects (`PAC_CONTROLLER_SECRET` env var), so it's controller-wide rather than per-`Repository`.

PAC originally ran on a webhook+PAT provider (a manually-registered repo webhook, `github-pac-token`/`github-pac-webhook-secret`, and a `git_provider` block on the `Repository` CR) -- switched to the GitHub App above once installed, since GitHub only allows Check Runs (the real Checks tab, not a flat commit status) to be created by an App, never a PAT regardless of scopes. The old repo-level webhook has been deleted; `github-pac-token`/`github-pac-webhook-secret` are still sitting in GSM unused -- fine to leave, or revoke the PAT and delete them if you want to fully retire that path.

## Pipelines

`PipelineRun` definitions live at [`.tekton/`](../../.tekton/) (repo root), not here:
- `build-and-push.yaml` -- Harbor image builds on push to `main`, scoped to `images/**`.
- `ci-checks.yaml` -- `kustomize build` + `yamllint` on PRs, scoped to files actually changed vs the target branch (diffed in a dedicated `changed-files` task) rather than the whole `kubernetes`/`okd` tree, so pre-existing debt elsewhere doesn't block unrelated PRs.

Notes:
- Reporting is via real GitHub Checks (the Checks tab, with log-snippet annotations on failure) now that PAC runs as a GitHub App -- see Manual Steps above.
- `build-and-push.yaml` hardcodes `image-name: steam-cmd` -- fix before a second image lands under `images/`.
- `build-and-push` stops at "image pushed" and never applies cluster manifests, so it won't need rework once ArgoCD exists.
- `git-clone`/`buildah` are fetched via Tekton's native `resolver: hub` (pinned to versions 0.10.0 / 0.9.0), **not** the `pipelinesascode.tekton.dev/task` annotation. That annotation resolves through PAC's own `hub-url` setting, which on this operator version still defaults to the decommissioned `api.hub.tekton.dev` and silently fails at runtime. The native hub-resolver's own config (`hubresolver-config` in `openshift-pipelines`) already points at Artifact Hub correctly, which is why it's used instead. Verified with a throwaway `TaskRun` before relying on it.

## Web Console

`pipelines-console-plugin` is registered in `okd/custom-configs/cluster-scope/console.yaml`, and loads/enables fine, but its list/overview pages (`/pipelines/...`, `/pipelines-overview/...`) crash on mount with `TypeError: (0 , r.useHistory) is not a function`. The plugin bundled in `okd-pipelines-operator.v1.7.0-2025-02-11-151011` was built against React Router v5 (`useHistory`), and this console version now vendors React Router v6, which dropped that hook. The `okderators` catalog only publishes this one CSV -- there's no newer build to upgrade to yet.

Generic Kubernetes resource pages (e.g. a `PipelineRun` details page reached via a PAC comment link) still render fine, since those use the console's own resource-details machinery rather than the plugin's custom list pages. Until `okderators` ships a fixed build, use `tkn`/`oc` for anything list-page-shaped (`tkn pipelinerun list -n tekton-ci`, etc.) instead of the console nav.

## Testing

```bash
oc get csv -n openshift-operators | grep -i pipelines
oc get tektonconfig config -o jsonpath='{.status.conditions}'

# after the webhook is live
tkn pipelinerun list -n tekton-ci
# push a commit touching images/steam-cmd/Dockerfile, or open a throwaway PR
```
