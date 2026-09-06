# CoreOS on Proxmox

[Fedora Project Discussion | CoreOS on Proxmox](https://discussion.fedoraproject.org/t/coreos-on-proxmox/26714/3)

[coreos/fedora-coreos-tracker](https://github.com/coreos/fedora-coreos-tracker/issues/736)

[Implement Proxmox VE (proxmoxve) Support #1652](https://github.com/coreos/fedora-coreos-tracker/issues/1652)

Example injecting ign file via CLI

```bash
pvesh create /nodes/pve/qemu/${VM_ID}/config/ --args "-fw_cfg name=opt/com.coreos/config,file=mnt/pve/tank-vz/snippets/ignition-file.ign"
```

```yaml
variant: fcos
version: 1.1.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmH+FS5LDsA3/PIqch0U4FfkKq8PVD1nWTHmOLbPsqdnplUIjf3915Sau/O1ozJNkjVhrE+FYvbd+8ebu0nCV+p83wge12N/3T8dhUpk47ZD64gODKpqBhHTxmraheO3xjK8IVxpjYxC5oXUMQXUB3r6NQ3K4pqnrxLcaIVaCBBjdINLwy+G0qkoxIiJU7bk1aMOo7YLOh3BufKomOPrbeklM7XzaEIgcMoqjKPJ1kNoTwVTthIo6pe1Dd47Ze2ed58SWn/ZtLAqiYJZbUbkNA99BNuEwKs/bifjJi/Lf2C0DLPklGEfLO8GTOZyYKh/K/aedx/UkH8x4MhrPJta9udw+lUCDU71ReCyEIFLn3TMrmLXq0Ed6fkbF8hzWBBvsc2VAmRvEAMDFyjcUmw/GTtrq9Dx45mxSq5QcDbcDyGGOqoRK/knDAt+dqI4Qs6Kl8vnXwg4GrYr1iMh2gdj+twaNDC6z8NpVp9L7e1Vi6Y2Xwi2W/NzceXDNxxkpTExc= gholland@RyzenDesk
```

```yaml
variant: fcos
version: 1.1.0
passwd:
  users:
    - name: garrett
      ssh_authorized_keys:
        - key1
      password_hash: password_hash
```

```bash
podman run --interactive --rm --security-opt label=disable --volume ${PWD}:/pwd --workdir /pwd quay.io/coreos/butane:release --pretty --strict standard.bu > transpiled_config.ign
```

HostKey /etc/ssh/desktop
