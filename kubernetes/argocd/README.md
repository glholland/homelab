# ArgoCD (OpenShift GitOps)

Installs ArgoCD via the `gitops-operator` package on the `okderators` CatalogSource, replacing the manual `kubectl kustomize | argocd-vault-plugin generate - | kubectl apply --server-side` flow with an in-cluster reconciler.

## Layout

```text
argocd/
├── base/
│   ├── subscription.yaml          # OLM Subscription for gitops-operator (openshift-operators)
│   └── installplan-approver-job.yaml
├── components/
│   └── wif-refresher/              # CronJob keeping GCP's copy of OKD's signing keys fresh
├── overlays/
│   └── okd/
│       ├── argocd-cr.yaml               # patches the operator's default ArgoCD CR (AVP sidecar, RBAC)
│       ├── cmp-configmap.yaml           # argocd-vault-plugin Config Management Plugin definition
│       ├── avp-credential-config.yaml   # AVP sidecar's GCP Workload Identity Federation config
│       └── repo-server-serviceaccount.yaml
├── applications/                   # app-of-apps: everything ArgoCD manages, including its own install
└── README.md
```

## Install

```bash
oc apply -k kubernetes/argocd/base
```

Approve the InstallPlan (automated by the Job in `base/`), then confirm:

```bash
oc get ns openshift-gitops
oc get argocd -n openshift-gitops
```

`gitops-operator` (channel `alpha`, `AllNamespaces`) mirrors `okd-pipelines-operator`'s install shape.

Fixed here, and in cert-manager/Tekton: `installplan-approver-job` referenced the in-cluster image registry, which this cluster runs with `managementState: Removed`. All three now use `quay.io/openshift/origin-cli:latest`.

## AVP sidecar

ArgoCD doesn't ship `argocd-vault-plugin`, so `argocd-cr.yaml` adds it as a Config Management Plugin sidecar on `argocd-repo-server` -- image omitted, so it inherits the repo-server's own (already has `kustomize`); an init container adds just the missing AVP binary. `cmp-configmap.yaml` runs `kustomize build . | argocd-vault-plugin generate -`, the same command every app's README documents running by hand today.

Every `Application` sets `spec.source.plugin.name: kustomize-avp` for this reason.

## GCP credentials: WIF, no downloaded key

AVP needs GSM access before it can resolve any placeholder, so this credential can't be an AVP-templated Secret. The sidecar authenticates with its own projected ServiceAccount token, exchanged through GCP STS -- same idea as `wif.tf`'s GitHub Actions federation.

A public tunnel doesn't work here: GCP requires `issuer_uri` to exactly match the token's `iss` claim, which is hardwired to the internal-only `https://kubernetes.default.svc` -- no tunnel makes that fetchable from the internet. So `argocd-wif.tf`'s provider uses a static `jwks_json` instead (`okd-jwks-seed.json`, seeded from `oc get --raw /openid/v1/jwks`) -- the one WIF mechanism that doesn't require fetching from `issuer_uri` at all.

`components/wif-refresher/` keeps that snapshot from going stale: a daily CronJob re-fetches the live JWKS and pushes it via `gcloud iam workload-identity-pools providers update-oidc`, authenticating the same WIF way under its own scoped identity (`roles/iam.workloadIdentityPoolAdmin` on just this one pool, nothing else). It bootstraps itself off OKD's signing-key rotation overlap window. `terraform apply` never fights these updates (`lifecycle.ignore_changes` on the provider's `oidc` block).

All of this lives in `argocd-wif.tf`, in the homelab's own project (`var.gcp_project_id`) -- not `wif.tf`'s Ty project. The repo-server runs under a dedicated `argocd-repo-server-avp` SA rather than the shared `default` one every other component uses, and the WIF provider's `attribute_condition` is scoped to exactly that identity plus the refresher's.

## OKD Specifics

- `AllNamespaces`-only, subscribed into `openshift-operators`, no `OperatorGroup`.
- Operator auto-creates the `openshift-gitops` namespace and a default `ArgoCD` CR -- `argocd-cr.yaml` patches it rather than creating a new one.
- No OpenShift `Group` objects exist on this cluster, so the operator's default group-based RBAC policy never matches -- `defaultPolicy: role:admin` covers the one identity that's already fully trusted.

## Manual Steps

`terraform apply` on `cloud/gcp/argocd-wif.tf` -- no external dependency to wait on. Re-seed `okd-jwks-seed.json` (`oc get --raw /openid/v1/jwks`) only if this provider is ever destroyed and recreated from scratch.

## Applications

App-of-apps: apply `root.yaml` once (`oc apply -k kubernetes/argocd/applications`); everything else in the directory becomes an `Application` from then on.

Curated to start, more apps follow the same pattern later:
- `gitops-operator` -- self-manages its own install.
- `okd-config` -- cluster OAuth/API-server config. Self-heal means manual console tweaks get reverted.
- `metallb`, `certman`, `external-dns` -- low-risk apps, to prove the pattern before anything stateful (harbor, zitadel, rook-ceph).

Manual sync only for now -- review each diff against what `kubectl kustomize | argocd-vault-plugin generate -` produces before syncing by hand. Flip to `syncPolicy.automated.selfHeal: true` (no `prune`) per app once trusted.

## Testing

```bash
oc get csv -n openshift-operators | grep -i gitops
oc get argocd openshift-gitops -n openshift-gitops -o jsonpath='{.status.phase}'

# AVP actually resolving GSM placeholders, not just running
oc logs -n openshift-gitops deploy/openshift-gitops-repo-server -c kustomize-avp

# WIF refresher actually keeping GCP's copy of OKD's signing keys current
oc get cronjob argocd-wif-refresher -n openshift-gitops
oc logs -n openshift-gitops -l job-name -c refresh --tail=20

oc get application -n openshift-gitops
```
