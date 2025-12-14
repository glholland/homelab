# Metal LB

## Helm to Kustomization

Adjust `values.yaml` as needed, then run:

```bash
helm template metallb metallb/metallb -f values.yaml > metallb.yaml
```

Uses `kfilt` to split Helm output into separate files by kind for easier management with Kustomize.

```bash
helm template metallb metallb/metallb --namespace metallb-system > all.yaml && \
for kind in $(grep "^kind:" all.yaml | awk '{print $2}' | sort -u | tr '[:upper:]' '[:lower:]'); do \
    kubectl kfilt -k "$kind" -f all.yaml > "./base/$kind.yaml"; \
done && \
rm all.yaml && \

cat <<EOF > ./base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: metallb-system
resources:
$(ls ./base | grep -v kustomization.yaml | awk '{print "  - " $0}')
EOF
```

## OKD

For OKD, remove the `securityContext` section from the `speaker` Deployment in `deployments.yaml` to avoid permission issues with running as non-root and `runAsUser`, `runAsGroup`, and `fsGroup` settings.

Permit the `ServiceAccount` used by MetalLB to run with the `privileged` Security Context Constraint (SCC) in OpenShift/OKD.

```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: metallb-speaker-privileged
  namespace: metallb-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: system:openshift:scc:privileged
subjects:
  - kind: ServiceAccount
    name: metallb-speaker
    namespace: metallb-system
```

## Memberlist Secret

The `metallb-memberlist` secret is required for the speaker to communicate. It must contain a `secretkey` field with a base64 encoded random string.

To generate the secret and append it to `base/secret.yaml`:

```bash
cat <<EOF >> base/secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: metallb-memberlist
  namespace: metallb-system
stringData:
  secretkey: "$(openssl rand -base64 128)"
EOF
```

## L2 Advertisement

For layer 2 advertisement (ARP for pods), create an `L2Advertisement` resource in the `metallb-system` namespace.

```bash
cat << EOF > overlays/okd/l2advertisement.yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
EOF
```

Then add it to the `kustomization.yaml` in the OKD overlay.

# Testing

After deploying MetalLB, test it by creating a `Service` of type `LoadBalancer` and verifying that it receives an external IP from the configured pool.

```bash
oc apply -f overlays/okd/test-service.yaml
```

Ping the new IP

```bash
curl $(oc get svc test-loadbalancer -n metallb-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```bash
oc delete -f overlays/okd/test-service.yaml
```
