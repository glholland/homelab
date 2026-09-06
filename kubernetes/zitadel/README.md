# zitadel

Identity provider intended to front OKD's OAuth eventually. Not wired in yet
-- OKD still authenticates directly against Google (`okd/config/base/oauth.yaml`)
until this is proven out.

## Layout

- `base/` -- Zitadel itself: Deployment, init/setup Jobs, Route, Certificate,
  RBAC, PDB, resource quota, and the masterkey/DSN secrets (argocd-vault-plugin
  placeholders, resolved with `AVP_TYPE=gcpsecretmanager`)
- `components/postgres/` -- a CloudNativePG `Cluster` for the database

## Database

Runs on [CloudNativePG](../cloudnative-pg/) rather than CockroachDB -- no
compatible OLM catalog exists on this cluster for CrunchyData's or any other
Postgres operator. Zitadel v2.56.0 has no `Database.postgres.DSN` field;
it connects via structured `Host`/`Port`/`Database`/`User`/`Admin` fields
instead (`sslmode=require`).

`User` is the low-privilege `zitadel` app role CNPG's `initdb` bootstrap
creates. `Admin` -- used only by the init/setup Jobs to create the app
role's grants -- needs real privileges, so the CNPG cluster runs with
`enableSuperuserAccess: true` and a self-supplied `zitadel-db-superuser`
secret (rather than CNPG's auto-generated one, to keep the password in
GSM like everything else).

`ca-bundle` holds Let's Encrypt's actual self-signed root (ISRG Root X1)
for the `reencrypt` route's `destinationCACertificate`. Without it,
OpenShift's router defaults to verifying the backend against the
cluster's internal service-ca and expecting a `*.zitadel.svc` hostname --
neither of which match the pod's public LE certificate, so every request
502s. Don't swap in a Let's Encrypt intermediate here: intermediates
rotate and aren't self-signed, so router-side chain verification rejects
them outright.

## Deploy

```bash
kubectl kustomize kubernetes/zitadel/overlay/okd \
  | AVP_TYPE=gcpsecretmanager argocd-vault-plugin generate - \
  | kubectl apply --server-side -f -
```

Requires the [cloudnative-pg](../cloudnative-pg/) operator already installed.
