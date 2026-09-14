# Tailscale Kubernetes Operator

## Helm to Kustomization

```bash
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm template tailscale-operator tailscale/tailscale-operator --version 1.102.3 --namespace tailscale -f values.yaml > all.yaml && \
for kind in $(grep "^kind:" all.yaml | awk '{print $2}' | sort -u | tr '[:upper:]' '[:lower:]'); do \
    kubectl kfilt -k "$kind" -f all.yaml > "./base/$kind.yaml"; \
done && \
rm all.yaml
```

`installCRDs: true` (chart default) means the `tailscale.com` CRDs (`Connector`, `ProxyClass`, `ProxyGroup`, etc.) render directly into `base/` -- no separate CRD-upgrade Job. The chart doesn't template a `Namespace`, so `base/namespace.yaml` is hand-written, same as every other hydrated app here.

## OAuth credential -- no chart-templated secret

`oauth.clientId`/`clientSecret` are left unset in `values.yaml` on purpose: the operator then expects a pre-existing Secret named `operator-oauth` (keys `client_id`, `client_secret`) instead of one Helm renders. `overlays/okd/oauth-secret.yaml` provides it, templated by argocd-vault-plugin from Google Secret Manager -- see Manual Steps.

## OKD Specifics

- `operatorConfig.extraEnv` sets `HOME=/tmp` on the operator `Deployment`: OKD's `restricted-v2` SCC runs the pod as an arbitrary non-root UID with no writable `$HOME`, and `tsnet` needs one to create its state dir (`~/.config/tsnet-operator`) -- fails with `mkdir /.config: permission denied` otherwise.
- Per-`Ingress` proxy pods (`ingressClassName: tailscale`) run Tailscale's userspace networking mode -- no kernel networking privilege needed, confirmed working against OKD's default SCC as-is, nothing added for them.
- The `Connector` (subnet router, below) is different in kind: it forwards arbitrary IP traffic, which needs a real TUN device (`CAP_NET_ADMIN`/`CAP_NET_RAW`) plus the ability to set `net.ipv4.ip_forward`/`net.ipv6.conf.all.forwarding` in its own network namespace -- capabilities and writes the default SCC strips.
  Two narrower approaches were tried first and both turned out to be dead ends on this cluster:
  - A custom `SecurityContextConstraints` scoped to just `NET_ADMIN`/`NET_RAW`, with the pod's own `securityContext.sysctls` declaring the forwarding sysctls -- rejected by the kubelet (`forbidden sysctl ... not allowlisted`) unless allowlisted cluster-wide via a `KubeletConfig`, which rolls every worker node.
  - A `Tuned` profile matching the proxy pod by label, setting the sysctls from the host side via `setns()` (bypassing the kubelet's sysctl gate entirely) -- this is a real OpenShift mechanism (used for DPDK/SR-IOV), but per-pod label matching in `Tuned.spec.recommend[].match` is deprecated on this OKD/NTO version; the `Tuned` object is rejected outright (`Valid: False`, `Deprecated pod label matching detected`) and never actually applies.

  Landed on the same pattern `metallb-speaker` uses instead: `overlays/okd/rolebinding-privileged.yaml` binds the `proxies` ServiceAccount to the built-in `system:openshift:scc:privileged` ClusterRole. This grants more than the Connector strictly needs (the metallb precedent, not the narrowly-scoped-SCC pattern used elsewhere in this repo), but a genuinely privileged container isn't subject to the sysctl-write restriction at all -- the tailscale operator's own default proxy pod spec already runs `privileged: true` when no `ProxyClass` overrides it, so no `ProxyClass` is needed here anymore either.

## Manual Steps

1. Tailscale admin console -> Access Controls -> add to `tagOwners`:
   ```json
   "tagOwners": {
     "tag:k8s-operator": ["autogroup:admin"],
     "tag:k8s":          ["tag:k8s-operator"],
   }
   ```
   Save this *before* creating the OAuth client below -- the client can't be tagged with a tag that doesn't exist yet.
2. Settings -> OAuth clients -> Generate OAuth client:
   - Scopes: **Devices Core** (Read/Write), **Keys > Auth Keys** (Read/Write), **General > Services** (Read/Write).
   - Tags: select **`tag:k8s-operator` only** (not `tag:k8s` too -- this is the client's own device identity; `tag:k8s-operator`'s ownership of `tag:k8s` from step 1 is what lets the running operator tag proxies it creates).
   - Copy both the Client ID and Client Secret immediately -- the secret is shown once.
3. `terraform apply` on `cloud/gcp/secretmanager.tf`, then add both values with `printf` (not `echo` -- a trailing newline breaks OAuth validation):
   ```bash
   printf '%s' 'CLIENT_ID' | gcloud secrets versions add tailscale-oauth-client-id --data-file=-
   printf '%s' 'CLIENT_SECRET' | gcloud secrets versions add tailscale-oauth-client-secret --data-file=-
   ```
4. Confirm "HTTPS Certificates" and MagicDNS are both enabled under the tailnet's DNS settings -- required for any `Ingress` to get a working `.ts.net` hostname + cert.

## Connector: home LAN subnet router

`overlays/okd/connector.yaml` advertises `10.0.0.0/16` (the home LAN) to the tailnet -- VPN-style access to non-Kubernetes devices (e.g. the UDM Pro's admin UI) by their normal IP, not per-service `Ingress` publishing. Subnet-router only, no exit node -- other internet traffic on a connected device stays off the home connection.

Advertised routes need manual approval: admin console -> **Machines** -> find `home-lan-router` -> approve the `10.0.0.0/16` route.

IP forwarding for this pod's network namespace comes for free from being privileged (see the `rolebinding-privileged.yaml` note above) -- nothing else to apply for it.

## Ingress: ArgoCD UI

`overlays/okd/ingress-argocd.yaml` exposes the GitOps `openshift-gitops-server` Service over Tailscale (`argocd.<tailnet>.ts.net`) via the userspace per-Ingress proxy -- same no-extra-privilege path already confirmed for `ingressClassName: tailscale` above, nothing SCC-related needed here. It lives in this overlay rather than under `kubernetes/argocd/` because it's Tailscale-specific exposure config, same reasoning as `connector.yaml`.

It targets the Service's `https` port directly (the GitOps operator serves TLS w/ a self-signed service-ca cert; the tailscale operator doesn't verify backend certs, so this works without flipping ArgoCD into `server.insecure` mode). Unverified against the live Service/port name -- confirm both once cluster access is back (`oc get svc -n openshift-gitops openshift-gitops-server -o yaml`).

## Apply

```bash
kubectl kustomize kubernetes/tailscale/overlays/okd | AVP_TYPE=gcpsecretmanager argocd-vault-plugin generate - | oc apply --server-side -f -
```

## Testing

```bash
oc get pod -n tailscale
oc get crd | grep tailscale.com
oc logs -n tailscale deploy/operator
```

Prove the ingress path end-to-end with a throwaway `Ingress` (`ingressClassName: tailscale`) pointed at any existing internal `ClusterIP` Service, then delete it:

```bash
oc get ingress <name> -o jsonpath='{.status}'   # operator should write back a .ts.net hostname
oc get statefulset -n tailscale                 # one proxy StatefulSet per active Ingress
```
