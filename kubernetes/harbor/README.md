# Harbor

## Helm to Kustomization

To regenerate the `base/` directory from the Helm chart:

```bash
# Ensure you are in kubernetes/harbor directory
helm repo add harbor https://helm.goharbor.io
helm repo update

helm template harbor harbor/harbor --namespace harbor -f values-override.yaml >| all.yaml && \
for kind in $(grep "^kind:" all.yaml | awk '{print $2}' | sort -u | tr '[:upper:]' '[:lower:]'); do \
    kubectl kfilt -k "$kind" -f all.yaml >| "./base/$kind.yaml"; \
done && \
rm all.yaml && \

cat <<YAML >| ./base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: harbor
resources:
$(ls ./base | grep -v kustomization.yaml | awk '{print "  - " $0}')
YAML
```

## Image Vendoring (Digest Pinning)

To resolve "ambiguous list" errors in OpenShift/OKD, replace image tags with SHA256 digests.

```bash
# Run this after generating the base manifests
../../scripts/vendor-images.sh
```

## OKD

The `overlays/okd` directory contains OpenShift-specific configurations:

- **Routes**: Replaces Ingress with OpenShift Routes (`overlays/okd/route.yaml`).
  - **Label**: Adds `type: lab` to ensure the route is handled by the `lab` IngressController (serving `*.lab.garrettholland.com`).
- **SCC**: Uses `harbor-anyuid` SCC to allow containers to run with any UID (`overlays/okd/scc.yaml`).
- **Patches**:
  - Removes `securityContext` (fsGroup, runAsUser) to let OpenShift handle permissions (`overlays/okd/patches.yaml`).
  - Removes `securityContext` from `registryctl` sidecar container (`overlays/okd/registry-patch.yaml`).
  - Removes `securityContext` from `data-permissions-ensurer` init container (`overlays/okd/database-patch.yaml`).

## Manual Steps

No specific manual steps required. Secrets are generated during the Helm template process and stored in `base/`.

## Testing

Deploy the application:

```bash
oc apply -k overlays/okd
```

Verify the route is accessible:

```bash
curl -I https://harbor.lab.garrettholland.com
```

> **Note**: The URL `harbor.lab.garrettholland.com` points to the HAProxy VIP for OKD deployed apps. Ensure your DNS is configured correctly.
> This deployment uses `cert-manager` to provision certificates from Let's Encrypt via the `harbor-cert` Certificate resource.

Check the status of the pods:

```bash
oc get pods -n harbor
```
