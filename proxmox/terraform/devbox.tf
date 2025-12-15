resource "proxmox_virtual_environment_vm" "dev_box" {
  name        = "dev-box"
  description = "Managed by Terraform"
  tags        = ["fcos", "fedora", "terraform"]
  bios        = "ovmf"
  node_name   = "pve"
  machine     = "q35"
  vm_id       = "1000"

  agent {
    enabled = true
  }

  stop_on_destroy = true
  on_boot         = true

  startup {
    order    = 1
    up_delay = 5
  }

  initialization {
    dns {
      domain  = "garrettholland.com"
      servers = ["10.0.0.1"]
    }

    user_account {
      username = var.virtual_environment_ssh_username
      keys     = [var.desktop_pub_key]
    }
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "00:00:00:10:AA:00"
  }

  operating_system {
    type = "l26"
  }

  memory {
    dedicated = 32768
  }

  cpu {
    type    = "host"
    cores   = 2
    sockets = 2
  }

  disk {
    interface    = "scsi0"
    size         = 120
    datastore_id = "local-lvm"
    file_format  = "raw"
  }

  efi_disk {
    type         = "4m"
    file_format  = "raw"
    datastore_id = "local-lvm"
  }
}
