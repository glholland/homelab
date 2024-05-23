terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.57.0"
    }
  }
}

terraform {
  backend "gcs" {
    bucket  = "proxmox-tfstate-26300"
    prefix  = "terraform/state"
  }
}

provider "proxmox" {
  endpoint = var.virtual_environment_endpoint
  username = var.virtual_environment_ssh_username
  password = var.virtual_environment_ssh_password
  # api_token = var.virtual_environment_api_token
  ssh{
    agent = true
  }
}
