# External DNS

External DNS manages a small set of explicitly requested DNS records in Pi-hole rather than publishing every Service, Ingress, or Route it sees.

This implementation uses the Pi-hole provider and is configured in opt-in mode. A resource must have the label `external-dns: enabled` before ExternalDNS will consider it. Custom aliases and targets are then controlled with the standard ExternalDNS annotations on that resource.

## Layout

The manifests are organized in a Kustomize layout:

```text
external-dns/
└── base/
    ├── namespace.yaml
    ├── service-account.yaml
    ├── rbac.yaml
    ├── deployment.yaml
    ├── secret.yaml
    └── kustomization.yaml
```

## Install

```bash
oc apply -k kubernetes/external-dns/base
```

## Opt-In Publishing

ExternalDNS is started with `--label-filter=external-dns=enabled`, so only explicitly labeled resources are published.

For an alias record, add the label and annotations to the resource you want ExternalDNS to watch:

```yaml
metadata:
  labels:
    external-dns: enabled
  annotations:
    external-dns.alpha.kubernetes.io/hostname: quay.garrettholland.com
    external-dns.alpha.kubernetes.io/target: harbor.lab.garrettholland.com
```

That configuration produces a DNS record for `quay.garrettholland.com` pointing at `harbor.lab.garrettholland.com` without publishing the rest of the cluster automatically.
