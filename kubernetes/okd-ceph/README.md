# Rook Ceph Deployment

This directory contains the Kustomize manifests for deploying the Rook Ceph Operator and Storage Cluster on OpenShift (OKD).

## Structure

- `base/`: GitOps resources for the Operator (Namespace, OperatorGroup, Subscription).
- `overlays/okd/`: Actual Storage Configuration.
  - **CephCluster:** Configured for `worker-1`, `worker-2`, `worker-3` using device `sda`.
  - **CephBlockPool:** Replicated Pool (Size 2).
  - **StorageClass:** `rook-ceph-block` (Default).

## Deployment

### 1. Deploy Operator

```bash
kustomize build base | oc apply -f -
```

_Wait for the operator to be ready._

### 2. Deploy Storage Cluster

```bash
kustomize build overlays/okd | oc apply -f -
```
