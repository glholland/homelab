# Cert-manager

[GitHub | cert-manager/cert-manager](https://github.com/cert-manager/cert-manager)

## Grab YAMLs

Organize YAMLs for Kustomization

```bash
wget https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml
```

## OLM InstallPlan Approval

`subscription.yaml` uses `installPlanApproval: Manual`. `components/operator/installplan-approver-job.yaml` auto-approves the resulting `InstallPlan` on apply (polls for up to 5 minutes, using the shared `installplan-approver` ServiceAccount/ClusterRole from `okd/config/base`). If a future version bump needs approving again, delete the completed Job first (`kubectl delete job approve-cert-manager-installplan -n openshift-operators`) then reapply -- Jobs are immutable once created, so re-running it means recreating it.
