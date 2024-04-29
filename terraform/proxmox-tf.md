# Proxmox Provider

[bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

## API Token Auth

### Create user and provide permissions

Create user

```bash
sudo pveum user add terraform@pve
```

Create Role

```bash
sudo pveum role add Terraform -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt User.Modify"
```

Assign Role

```bash
sudo pveum aclmod / -user terraform@pve -role Terraform
```

Create API token

```bash
sudo pveum user token add terraform@pve provider --privsep=0
```
