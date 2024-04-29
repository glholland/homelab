variable "virtual_environment_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API (example: https://host:port)"
  default     = "https://pve.garrettholland.com:8006/"
}

variable "virtual_environment_api_token" {
  type        = string
  description = "The API token for the Proxmox Virtual Environment API"
  default     = "token"
}

variable "virtual_environment_username" {
  type        = string
  description = "The username and realm for the Proxmox Virtual Environment API (example: root@pam)"
  default     = "terraform@pve"
}

variable "latest_ubuntu_22_jammy_qcow2_img" {
  type    = string
  default = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}
