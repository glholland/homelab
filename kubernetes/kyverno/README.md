# Kyverno

Kubernetes-native policy engine. Brought in for one narrow reason: the `okderators` `okd-pipelines-operator` (v1.7.0-2025-02-11-151011, used by [`kubernetes/tekton`](../tekton/)) ships a packaging bug where the `pipelines-as-code-watcher` and `pipelines-as-code-webhook` Deployments never override their container `command`, so both silently fall through to the image's default entrypoint -- the `pipelines-as-code-controller` binary -- instead of their own. See [`policies/fix-pac-watcher-webhook-binary.yaml`](policies/fix-pac-watcher-webhook-binary.yaml) for the full writeup and fix.

No OLM path exists for Kyverno on this cluster (not in `community-operators` or `okderators`, and self-hosting a catalog image just for this is more infrastructure than it's worth), so this is installed via Kyverno's own supported method -- the Helm chart -- hydrated to static manifests, same as [`kubernetes/metallb`](../metallb/).

## Helm to Kustomization

Adjust `values.yaml` as needed, then run:

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update kyverno
helm template kyverno kyverno/kyverno --version 3.9.0 --namespace kyverno -f values.yaml > all.yaml
```

Uses `kfilt` to split Helm output into separate files by kind for easier management with Kustomize.

```bash
for kind in $(grep "^kind:" all.yaml | awk '{print $2}' | sort -u | tr '[:upper:]' '[:lower:]'); do
    kubectl kfilt -k "$kind" -f all.yaml > "./base/$kind.yaml"
done
rm all.yaml
```

Delete `base/pod.yaml` and `base/job.yaml` after splitting -- both are Helm test/upgrade/delete hooks (`helm.sh/hook` annotations) that only make sense under live Helm lifecycle management, not a static apply. Add `base/namespace.yaml` by hand (the chart doesn't render one) and regenerate `base/kustomization.yaml`'s resource list from whatever's left.

## OKD

Every controller's securityContext hardcodes `runAsUser: 65534` / `runAsGroup: 65534`, which the `restricted` SCC rejects since that UID won't fall in the namespace's allocated range. `overlays/okd/security-context-patch.yaml` nulls both out on all four controllers so OpenShift assigns them dynamically -- everything else in the chart's default securityContext (`runAsNonRoot`, dropped capabilities, `readOnlyRootFilesystem`) is already `restricted`-compatible as-is.

Trimmed all four controllers (`admissionController`, `backgroundController`, `cleanupController`, `reportsController`) to 1 replica each in `values.yaml` -- the chart defaults to HA-oriented replica counts that are overkill for a single-purpose homelab install.

## Policies

[`policies/fix-pac-watcher-webhook-binary.yaml`](policies/fix-pac-watcher-webhook-binary.yaml) -- a `mutate` `ClusterPolicy` that forces the correct `command` onto the `pipelines-as-code-watcher` and `pipelines-as-code-webhook` Deployments in `openshift-pipelines` on every create/update. Has to be admission-time (`background: false`), not a one-off patch, because the `TektonConfig` operator continuously reconciles those Deployments back to its own (buggy) desired state -- confirmed by patching the watcher's `command` directly and watching the operator revert it within moments. The operator's own `TektonInstallerSet` source manifest lacks the override too, so there's no config layer above the Deployment itself worth patching instead.

`failurePolicy: Ignore` so a Kyverno hiccup can't block updates to these Deployments -- the policy only matches two specifically-named resources in one namespace, so the blast radius of *not* enforcing briefly is small.

## Testing

```bash
oc get pods -n kyverno
oc get clusterpolicy fix-pac-watcher-webhook-binary -o jsonpath='{.status}'

# confirm the fix actually took
oc exec -n openshift-pipelines deployment/pipelines-as-code-watcher -- cat /proc/1/cmdline
oc exec -n openshift-pipelines deployment/pipelines-as-code-webhook -- cat /proc/1/cmdline
# both should print /ko-app/pipelines-as-code-<watcher|webhook>, not -controller
```
