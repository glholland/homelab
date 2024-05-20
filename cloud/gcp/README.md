# GCP Terraform

## Usage

Make CLI identity available to TF

```bash
gcloud auth application-default login
```

Login & seed secrets

```bash
gcloud auth login
gcloud secrets versions access 1 --secret=secrets_tfvars --out-file=secrets.tfvars
```

Apply TF!
