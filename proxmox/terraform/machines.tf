// resource "proxmox_virtual_environment_vm" "master-1" {
// 	name = "master-1"
// 	description = "Managed by Terraform"
// 	tags 				= ["terraform", "fcos", "okd"]
// 	bios      = "ovmf"
//   node_name = "pve"
//   machine   = "q35"

// 	vm_id 			= "200"
// 	agent {
// 		enabled = false
// 	}

// 	stop_on_destroy = true

// 	startup {
// 		order    = 1
// 		up_delay = 5
// 	}

// 	clone{
// 		vm_id = 900
// 		full  = true
// 	}

// 	network_device {
// 		bridge = "vmbr0"
// 		model = "virtio"
// 		mac_address = "00:00:00:00:AA:00"
// 	}

// 	operating_system {
//     type = "l26"
//   }

//   tpm_state {
//     version = "v2.0"
//   }

//   // memory {
//   //   dedicated = 16384
//   // }

//   cpu {
//     type  = "host"
//     cores = "8"
//   }

//   disk {
//     interface = "scsi0"
//     size      = 50
//   }

//   efi_disk {
//     type        = "4m"
//     file_format = "raw"
//   }

// 	initialization {
// 		dns {
// 			domain = "garrettholland.com"
// 			servers = ["10.0.0.1"]
// 		}

// 		ip_config {
// 			ipv4 {
// 				address = "10.0.10.210/16"
// 				gateway = "10.0.0.1"
// 			}
// 		}

// 		user_account {
// 			keys = [var.desktop_pub_key]
// 			username = "garrett"
// 		}
// 	}
// 	hook_script_file_id = var.hook_script_id
// }

// resource "proxmox_virtual_environment_vm" "master-2" {
// 	name = "master-2"
// 	description = "Managed by Terraform"
// 	tags 				= ["terraform", "fcos", "okd"]
// 	bios      = "ovmf"
//   node_name = "pve"
//   machine   = "q35"

// 	vm_id 			= "201"
// 	agent {
// 		enabled = false
// 	}

// 	stop_on_destroy = true

// 	startup {
// 		order    = 1
// 		up_delay = 5
// 	}

// 	clone{
// 		vm_id = 900
// 		full  = true
// 	}

// 	network_device {
// 		bridge = "vmbr0"
// 		model = "virtio"
// 		mac_address = "00:00:00:00:AA:01"
// 	}

// 	operating_system {
//     type = "l26"
//   }

//   tpm_state {
//     version = "v2.0"
//   }

//   // memory {
//   //   dedicated = 16384
//   // }

//   cpu {
//     type  = "host"
//     cores = "8"
//   }

//   disk {
//     interface = "scsi0"
//     size      = 50
//   }

//   efi_disk {
//     type        = "4m"
//     file_format = "raw"
//   }

// 	initialization {
// 		dns {
// 			domain = "garrettholland.com"
// 			servers = ["10.0.0.1"]
// 		}

// 		ip_config {
// 			ipv4 {
// 				address = "10.0.10.211/16"
// 				gateway = "10.0.0.1"
// 			}
// 		}

// 		user_account {
// 			keys = [var.desktop_pub_key]
// 			username = "garrett"
// 		}
// 	}
// 	hook_script_file_id = var.hook_script_id
// }

// resource "proxmox_virtual_environment_vm" "master-3" {
// 	name = "master-3"
// 	description = "Managed by Terraform"
// 	tags 				= ["terraform", "fcos", "okd"]
// 	bios      = "ovmf"
//   node_name = "pve"
//   machine   = "q35"

// 	vm_id 			= "202"
// 	agent {
// 		enabled = false
// 	}

// 	stop_on_destroy = true

// 	startup {
// 		order    = 1
// 		up_delay = 5
// 	}

// 	clone{
// 		vm_id = 900
// 		full  = true
// 	}

// 	network_device {
// 		bridge = "vmbr0"
// 		model = "virtio"
// 		mac_address = "00:00:00:00:AA:02"
// 	}

// 	operating_system {
//     type = "l26"
//   }

//   tpm_state {
//     version = "v2.0"
//   }

//   // memory {
//   //   dedicated = 16384
//   // }

//   cpu {
//     type  = "host"
//     cores = "8"
//   }

//   disk {
//     interface = "scsi0"
//     size      = 50
//   }

//   efi_disk {
//     type        = "4m"
//     file_format = "raw"
//   }

// 	initialization {
// 		dns {
// 			domain = "garrettholland.com"
// 			servers = ["10.0.0.1"]
// 		}

// 		ip_config {
// 			ipv4 {
// 				address = "10.0.10.212/16"
// 				gateway = "10.0.0.1"
// 			}
// 		}

// 		user_account {
// 			keys = [var.desktop_pub_key]
// 			username = "garrett"
// 		}
// 	}
// 	hook_script_file_id = var.hook_script_id
// }

// resource "proxmox_virtual_environment_vm" "worker-1" {
// 	name = "worker-1"
// 	description = "Managed by Terraform"
// 	tags 				= ["terraform", "fcos", "okd"]
// 	bios      = "ovmf"
//   node_name = "pve"
//   machine   = "q35"

// 	vm_id 			= "203"
// 	agent {
// 		enabled = false
// 	}

// 	stop_on_destroy = true

// 	startup {
// 		order    = 1
// 		up_delay = 5
// 	}

// 	clone{
// 		vm_id = 900
// 		full  = true
// 	}

// 	network_device {
// 		bridge = "vmbr0"
// 		model = "virtio"
// 		mac_address = "00:00:00:00:AA:03"
// 	}

// 	operating_system {
//     type = "l26"
//   }

//   tpm_state {
//     version = "v2.0"
//   }

//   // memory {
//   //   dedicated = 16384
//   // }

//   cpu {
//     type  = "host"
//     cores = "8"
//   }

//   disk {
//     interface = "scsi0"
//     size      = 50
//   }

//   efi_disk {
//     type        = "4m"
//     file_format = "raw"
//   }

// 	initialization {
// 		dns {
// 			domain = "garrettholland.com"
// 			servers = ["10.0.0.1"]
// 		}

// 		ip_config {
// 			ipv4 {
// 				address = "10.0.10.213/16"
// 				gateway = "10.0.0.1"
// 			}
// 		}

// 		user_account {
// 			keys = [var.desktop_pub_key]
// 			username = "garrett"
// 		}
// 	}
// 	hook_script_file_id = var.hook_script_id
// }

// resource "proxmox_virtual_environment_vm" "worker-2" {
// 	name = "worker-2"
// 	description = "Managed by Terraform"
// 	tags 				= ["terraform", "fcos", "okd"]
// 	bios      = "ovmf"
//   node_name = "pve"
//   machine   = "q35"

// 	vm_id 			= "204"
// 	agent {
// 		enabled = false
// 	}

// 	stop_on_destroy = true

// 	startup {
// 		order    = 1
// 		up_delay = 5
// 	}

// 	clone{
// 		vm_id = 900
// 		full  = true
// 	}

// 	network_device {
// 		bridge = "vmbr0"
// 		model = "virtio"
// 		mac_address = "00:00:00:00:AA:04"
// 	}

// 	operating_system {
//     type = "l26"
//   }

//   tpm_state {
//     version = "v2.0"
//   }

//   // memory {
//   //   dedicated = 16384
//   // }

//   cpu {
//     type  = "host"
//     cores = "8"
//   }

//   disk {
//     interface = "scsi0"
//     size      = 50
//   }

//   efi_disk {
//     type        = "4m"
//     file_format = "raw"
//   }

// 	initialization {
// 		dns {
// 			domain = "garrettholland.com"
// 			servers = ["10.0.0.1"]
// 		}

// 		ip_config {
// 			ipv4 {
// 				address = "10.0.10.214/16"
// 				gateway = "10.0.0.1"
// 			}
// 		}

// 		user_account {
// 			keys = [var.desktop_pub_key]
// 			username = "garrett"
// 		}
// 	}
// 	hook_script_file_id = var.hook_script_id
// }

// resource "proxmox_virtual_environment_vm" "worker-3" {
// 	name = "worker-3"
// 	description = "Managed by Terraform"
// 	tags 				= ["terraform", "fcos", "okd"]
// 	bios      = "ovmf"
//   node_name = "pve"
//   machine   = "q35"

// 	vm_id 			= "205"
// 	agent {
// 		enabled = false
// 	}

// 	stop_on_destroy = true

// 	startup {
// 		order    = 1
// 		up_delay = 5
// 	}

// 	clone{
// 		vm_id = 900
// 		full  = true
// 	}

// 	network_device {
// 		bridge = "vmbr0"
// 		model = "virtio"
// 		mac_address = "00:00:00:00:AA:05"
// 	}

// 	operating_system {
//     type = "l26"
//   }

//   tpm_state {
//     version = "v2.0"
//   }

//   // memory {
//   //   dedicated = 16384
//   // }

//   cpu {
//     type  = "host"
//     cores = "8"
//   }

//   disk {
//     interface = "scsi0"
//     size      = 50
//   }

//   efi_disk {
//     type        = "4m"
//     file_format = "raw"
//   }

// 	initialization {
// 		dns {
// 			domain = "garrettholland.com"
// 			servers = ["10.0.0.1"]
// 		}

// 		ip_config {
// 			ipv4 {
// 				address = "10.0.10.215/16"
// 				gateway = "10.0.0.1"
// 			}
// 		}

// 		user_account {
// 			keys = [var.desktop_pub_key]
// 			username = "garrett"
// 		}
// 	}
// 	hook_script_file_id = var.hook_script_id
// }

resource "proxmox_virtual_environment_vm" "okd-master-1" {
	name = "okd-master-1"
	description = "Managed by Terraform"
	tags 				= ["terraform", "fcos", "okd"]
	bios      = "ovmf"
  node_name = "pve"
  machine   = "q35"

	vm_id 			= "305"

	agent {
		enabled = false
	}

	stop_on_destroy = true

	startup {
		order    = 1
		up_delay = 5
	}

	// clone{
	// 	vm_id = 900
	// 	full  = true
	// }

	network_device {
		bridge = "vmbr0"
		model = "virtio"
		mac_address = "00:00:00:00:AA:00"
	}

	smbios {
		serial = "okd-master-1"
		manufacturer = "garrettholland"
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
		// file_id		= "local:iso/rhcos-full-iso-4.15-40.20240519.3.0-x86_64.iso"
  }

	cdrom {
		enabled = true
		file_id = "local:iso/okd-discovery.iso"
	}

  efi_disk {
    type        = "4m"
    file_format = "raw"
  }

	 initialization {
	 	dns {
	 		domain = "garrettholland.com"
	 		servers = ["10.0.0.1"]
		}
	 	ip_config {
	 		ipv4 {
	 			address = "10.0.0.210/16"
	 			gateway = "10.0.0.1"
	 		}
		}
		user_account {
	 		keys = [var.desktop_pub_key]
	 		username = "garrett"
		}
	}
	hook_script_file_id = var.hook_script_id
}
// data "proxmox_virtual_environment_vms" "existing_vms" {}

// data "ignition_file" "k3s_server_config" {
//   path = "/etc/rancher/k3s/config.yaml.d/server.yaml"
//   content {
//     content = var.ipv4_addr.addr == var.rendevous_host ? "cluster-init: true\ntoken: '${var.k3s_server_token}'" : "server: 'https://${var.rendevous_host}:6443'\ntoken: '${var.k3s_server_token}'"
//   }
// }

// data "ignition_file" "k3s_agent_config" {
//   path = "/etc/rancher/k3s/config.yaml.d/agent.yaml"
//   content {
//     content = "agent-token: '${var.k3s_agent_token}'\n"
//   }
// }

// data "ignition_config" "ignition_config" {
//   files = [
//     sensitive(data.ignition_file.k3s_server_config.rendered),
//     sensitive(data.ignition_file.k3s_agent_config.rendered),
//   ]
//   merge {
//     source = format("data:;base64,%s", base64encode(file("/private/tmp/k3s_init/k3s.ign")))
//   }
// }

// resource "proxmox_virtual_environment_file" "base_ignition" {
//   content_type = "snippets"
//   datastore_id = "local"
//   node_name    = var.proxmox_node

//   source_raw {
//     data      = sensitive(data.ignition_config.ignition_config.rendered)
//     file_name = "${var.vm_hostname}-base.ign"
//   }
// }

// resource "proxmox_virtual_environment_vm" "k3s_server_vm" {
//   initialization {
//     dns {
//       servers = [var.nameserver]
//     }
//     ip_config {
//       ipv4 {
//         address = "${var.ipv4_addr.addr}%{if var.ipv4_addr.mask != ""}/${var.ipv4_addr.mask}%{endif}"
//         gateway = var.ipv4_gw
//       }
//     }
//     user_account {
//       keys     = var.cloudinit_ssh_keys
//       username = var.cloudinit_username
//       password = var.cloudinit_password
//     }
//   }
//   agent {
//     enabled = true # this will cause terraform operations to hang if the Qemu agent doesn't install correctly!
//   }
//   name = var.vm_hostname
//   tags = sort(
//     concat(
//       ["${var.vm_os}", "tofu"],
//       var.vm_tags,
//     )
//   )
//   bios      = "ovmf"
//   node_name = var.proxmox_node
//   machine   = "q35"
//   memory {
//     dedicated = var.vm_memory_mb
//   }

//   cpu {
//     type  = "host"
//     cores = "2"
//   }

//   disk {
//     interface = "scsi0"
//     size      = var.vm_disksize
//   }
//   efi_disk {
//     type        = "4m"
//     file_format = "raw"
//   }
//   clone {
//     vm_id = lookup(
//       zipmap(
//         data.proxmox_virtual_environment_vms.existing_vms.vms[*].name,
//         data.proxmox_virtual_environment_vms.existing_vms.vms[*].vm_id
//       ),
//       "${var.vm_os}-latest"
//     )
//     full = true
//   }

//   network_device {
//     bridge = "vmbr0"
//     model  = "virtio"
//   }

//   operating_system {
//     type = "l26"
//   }

//   tpm_state {
//     version = "v2.0"
//   }
//   kvm_arguments = "-fw_cfg name=opt/com.coreos/config,file=/var/lib/vz/snippets/${var.vm_hostname}.ign"
//   vga {
//     enabled = true
//     memory  = 16
//     type    = "std"
//   }
//   # serial_device {}
//   hook_script_file_id = var.hook_script_id
// }
