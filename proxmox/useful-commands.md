# Useful Commands

Commands

```bash
NEXTID=${pvesh get /cluster/nextid}

pvesh create /nodes/pve/qemu \
-vmid 101 -memory 2048 \
-sockets 1 -cores 4 \
-net0 e1000,bridge=vmbr0 \
-net1 e1000,bridge=vmbr1 \
-ide0=local:101/vm-101-disk-0.qcow2 \
-ide2 local:iso/ubuntu-14.04-server-amd64.iso,media=cdrom
```
