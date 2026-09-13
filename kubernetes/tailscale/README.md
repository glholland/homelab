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
- The `Connector` (subnet router, below) is different in kind: it forwards arbitrary IP traffic, which needs a real TUN device (`CAP_NET_ADMIN`/`CAP_NET_RAW`) -- capabilities the default SCC strips. Rather than bind to the built-in `system:openshift:scc:privileged` (the `metallb-speaker` pattern, which grants far more than needed), `overlays/okd/scc.yaml` defines a custom `SecurityContextConstraints` scoped to exactly those two capabilities for just the `proxies` ServiceAccount -- same self-scoped-SCC pattern already used by `telegraf`/`harbor`/etc. `overlays/okd/proxyclass.yaml` adds the capabilities to the proxy pod spec; the `Connector` references it via `spec.proxyClass`.

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
