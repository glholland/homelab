resource "proxmox_virtual_environment_vm" "fcos_clone" {
	name = "clone-test"
	description = "Managed by Terraform"
	tags 				= ["terraform", "fcos"]

	node_name 	= "pve"
	vm_id 			= "1234"
	agent {
		enabled = false
	}

	stop_on_destroy = true

	startup {
		order = 1
		up_delay = 5
	}

	clone{
		vm_id = 900

	}
}
