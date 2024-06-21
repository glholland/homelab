resource "proxmox_virtual_environment_download_file" "fedora-40" {
  content_type = "iso"
  datastore_id = "local"
  node_name = "pve"
  url = "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-40-1.14.iso"
}

resource "proxmox_virtual_environment_vm" "dev_box" {
	name = "dev-box"
	description = "Managed by Terraform"
	tags 				= ["terraform", "fcos", "fedora"]
	bios      = "ovmf"
  node_name = "pve"
  machine   = "q35"

	vm_id 			= "1000"

	agent {
		enabled = true
	}

	stop_on_destroy = true

	startup {
		order    = 1
		up_delay = 5
	}

  initialization {
    dns {
      domain  = var.dns_domain
      servers = ["10.0.0.1"]
    }

    user_account {
      username = var.virtual_environment_ssh_username
      keys     = [var.desktop_pub_key]
    }
  // user_data_file_id = var.user_data_file_id
  }

	network_device {
		bridge      = "vmbr0"
		model       = "virtio"
		mac_address = "00:00:00:10:AA:00"
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
    type  = "host"
    cores = "8"
  }

  disk {
    interface = "scsi0"
    size      = 100
		datastore_id = "local-lvm"
		file_format = "raw"
  }

  efi_disk {
    type        = "4m"
    file_format = "raw"
  }
}
