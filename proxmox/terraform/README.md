# Proxmox Terraform Usage

Login & seed secrets

```bash
gcloud auth login
gcloud secrets versions access 1 --secret=proxmox_tfvars --out-file=secrets.tfvars
```

Apply!

```bash
terraform apply --var-file=secrets.tfvars
```
