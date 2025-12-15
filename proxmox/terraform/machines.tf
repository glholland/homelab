resource "proxmox_virtual_environment_vm" "master-1" {
  name        = "master-1"
  description = "Managed by Terraform"
  tags        = ["terraform", "fcos", "okd"]
  bios        = "ovmf"
  node_name   = "pve"
  machine     = "q35"
  vm_id       = "200"
  boot_order  = ["virtio0", "ide3"]
  agent {
    enabled = false
  }
  cdrom {
    enabled = true
    file_id = "local:iso/agent.x86_64.iso"
  }
  stop_on_destroy = true
  startup {
    order    = 1
    up_delay = 5
  }
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mtu         = "1"
    mac_address = "00:00:00:00:AA:00"
  }
  operating_system {
    type = "l26"
  }
  tpm_state {
    version = "v2.0"
  }
  memory {
    dedicated = 32768
  }
  cpu {
    architecture = "x86_64"
    type         = "host"
    cores        = "8"
  }
  disk {
    interface   = "virtio0"
    size        = 120
    file_format = "raw"
  }
  efi_disk {
    type        = "4m"
    file_format = "raw"
  }
}
resource "proxmox_virtual_environment_vm" "master-2" {
  name        = "master-2"
  description = "Managed by Terraform"
  tags        = ["terraform", "fcos", "okd"]
  bios        = "ovmf"
  node_name   = "pve"
  machine     = "q35"
  vm_id       = "201"
  boot_order  = ["virtio0", "ide3"]
  agent {
    enabled = false
  }
  cdrom {
    enabled = true
    file_id = "local:iso/agent.x86_64.iso"
  }
  stop_on_destroy = true
  startup {
    order    = 1
    up_delay = 5
  }
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mtu         = "1"
    mac_address = "00:00:00:00:AA:01"
  }

  operating_system {
    type = "l26"
  }
  tpm_state {
    version = "v2.0"
  }
  memory {
    dedicated = 32768
  }
  cpu {
    architecture = "x86_64"
    type         = "host"
    cores        = "8"
  }
  disk {
    interface   = "virtio0"
    size        = 120
    file_format = "raw"
  }
  efi_disk {
    type        = "4m"
    file_format = "raw"
  }
}
resource "proxmox_virtual_environment_vm" "master-3" {
  name        = "master-3"
  description = "Managed by Terraform"
  tags        = ["terraform", "fcos", "okd"]
  bios        = "ovmf"
  node_name   = "pve"
  machine     = "q35"
  vm_id       = "202"
  boot_order  = ["virtio0", "ide3"]
  agent {
    enabled = false
  }

  cdrom {
    enabled = true
    file_id = "local:iso/agent.x86_64.iso"
  }

  stop_on_destroy = true
  startup {
    order    = 1
    up_delay = 5
  }
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mtu         = "1"
    mac_address = "00:00:00:00:AA:02"
  }
  operating_system {
    type = "l26"
  }
  tpm_state {
    version = "v2.0"
  }
  memory {
    dedicated = 32768
  }
  cpu {
    architecture = "x86_64"
    type         = "host"
    cores        = "8"
  }
  disk {
    interface   = "virtio0"
    size        = 120
    file_format = "raw"
  }
  efi_disk {
    type        = "4m"
    file_format = "raw"
  }
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys     = [var.desktop_pub_key]
      username = "garrett"
    }
  }
}
resource "proxmox_virtual_environment_vm" "worker-1" {
  name        = "worker-1"
  description = "Managed by Terraform"
  tags        = ["terraform", "fcos", "okd"]
  bios        = "ovmf"
  node_name   = "pve"
  machine     = "q35"
  vm_id       = "203"
  boot_order  = ["virtio0", "ide3"]
  agent {
    enabled = false
  }

  cdrom {
    enabled = true
    file_id = "local:iso/agent.x86_64.iso"
  }

  stop_on_destroy = true
  startup {
    order    = 1
    up_delay = 5
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mtu         = "1"
    mac_address = "00:00:00:00:AA:03"
  }
  operating_system {
    type = "l26"
  }
  tpm_state {
    version = "v2.0"
  }
  memory {
    dedicated = 16384
  }
  cpu {
    architecture = "x86_64"
    type         = "host"
    cores        = "8"
  }
  disk {
    interface   = "virtio0"
    size        = 120
    file_format = "raw"
  }
  efi_disk {
    type        = "4m"
    file_format = "raw"
  }
}
resource "proxmox_virtual_environment_vm" "worker-2" {
  name        = "worker-2"
  description = "Managed by Terraform"
  tags        = ["terraform", "fcos", "okd"]
  bios        = "ovmf"
  node_name   = "pve"
  machine     = "q35"
  vm_id       = "204"
  boot_order  = ["virtio0", "ide3"]
  agent {
    enabled = false
  }

  cdrom {
    enabled = true
    file_id = "local:iso/agent.x86_64.iso"
  }

  stop_on_destroy = true
  startup {
    order    = 1
    up_delay = 5
  }
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mtu         = "1"
    mac_address = "00:00:00:00:AA:04"
  }
  operating_system {
    type = "l26"
  }
  tpm_state {
    version = "v2.0"
  }
  memory {
    dedicated = 16384
  }
  cpu {
    architecture = "x86_64"
    type         = "host"
    cores        = "8"
  }
  disk {
    interface   = "virtio0"
    size        = 120
    file_format = "raw"
  }
  efi_disk {
    type        = "4m"
    file_format = "raw"
  }
}
resource "proxmox_virtual_environment_vm" "worker-3" {
  name        = "worker-3"
  description = "Managed by Terraform"
  tags        = ["terraform", "fcos", "okd"]
  bios        = "ovmf"
  node_name   = "pve"
  machine     = "q35"
  vm_id       = "205"
  boot_order  = ["virtio0", "ide3"]
  agent {
    enabled = false
  }

  cdrom {
    enabled = true
    file_id = "local:iso/agent.x86_64.iso"
  }

  stop_on_destroy = true
  startup {
    order    = 1
    up_delay = 5
  }
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mtu         = "1"
    mac_address = "00:00:00:00:AA:05"
  }
  operating_system {
    type = "l26"
  }
  tpm_state {
    version = "v2.0"
  }
  memory {
    dedicated = 16384
  }
  cpu {
    architecture = "x86_64"
    type         = "host"
    cores        = "8"
  }
  disk {
    interface   = "virtio0"
    size        = 120
    file_format = "raw"
  }
  efi_disk {
    type        = "4m"
    file_format = "raw"
  }
}
