terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.54.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.virtual_environment_endpoint
  username  = var.virtual_environment_username
  password  = "password"
  api_token = var.virtual_environment_api_token
  insecure  = true
  ssh {
    agent    = true
    username = "terraform"
  }
}
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name        = "terraform-provider-proxmox-ubuntu-vm"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu"]

  node_name = "pve"
  vm_id     = 4321

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = false
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = "local-lvm:iso/jammy-server-cloudimg-amd64.img"
    interface    = "scsi0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.0.0.101/24"
        gateway = "10.0.0.1"
      }
    }

    dns {
      domain  = "garrettholland.com"
      servers = ["10.0.0.1"]
    }

    user_account {
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
      password = random_password.ubuntu_vm_password.result
      username = "ubuntu"
    }

    #user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  tpm_state {
    version = "v2.0"
  }

}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_qcow2_img" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

resource "random_password" "ubuntu_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_vm_password" {
  value     = random_password.ubuntu_vm_password.result
  sensitive = true
}

output "ubuntu_vm_private_key" {
  value     = tls_private_key.ubuntu_vm_key.private_key_pem
  sensitive = true
}

output "ubuntu_vm_public_key" {
  value = tls_private_key.ubuntu_vm_key.public_key_openssh
}
