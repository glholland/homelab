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

variable "desktop_pub_key" {
	type = string
	sensitive = true
}

variable "hook_script_id" {
	type = string
}

variable "dns_domain" {
	type = string
	sensitive = true
}
