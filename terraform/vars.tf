variable "ssh_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd1CXzwIpft5wVA/WJqvEk6DH4UmiLmmroZ0IXUcWYmXNWlnvhJx4eFrviz6GyUyDt9hdG69lBScIag5D6UD3ivVFYmBSXkwIludDgA6FeYQfVvpBCR25XgiabpWHhXItbXIYiigzeSF+lmJw6KF+0gTPPKVFtpg8h/eM8j26+lNbGiebYWNbZ0iBRNDZNmrxQAIsgWAszPvZSyZrkFvsLT8U258WsfZbW6q+WelGHQEL4dV2YkfMTZ/jJhq+cOv4Zr7tcbUSw3m90BJ45PhTYEozN0S1GAzyaDchcFabl/RRLa90x+vjJIrp8P/cZVlBunVNtL0HM121QqGiBj8nn garrett@RyzenDesk"
}
variable "proxmox_host" {
    default = "pve"
}
variable "template_name" {
    default = "fcos-tmplt"
}