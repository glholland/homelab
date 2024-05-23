variable "virtual_environment_endpoint" {
  description = "URL for Proxmox"
	type = string
	sensitive = true
}

variable "virtual_environment_api_token" {
  default = "pve"
  description = "API token for proxmox"
	type = string
	sensitive = true
}

variable "virtual_environment_ssh_username" {
	type = string
	sensitive = true
}

variable "virtual_environment_ssh_password" {
	type = string
	sensitive = true
}
