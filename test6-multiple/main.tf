# SINGLE
terraform {
  required_version = ">= 0.13"
  required_providers {
    esxi = {
      source  = "registry.terraform.io/josenk/esxi"
      version = "~> 1.7.1"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

# Define our variables here.  Set them in terraform.tfvars
variable "my_esxi_hostname" { type = string }
variable "my_esxi_username" { type = string }
variable "my_esxi_password" { type = string }
variable "my_esxi_hostport" {
  type = number
  default = 22
}
variable "my_esxi_hostssl" {
  type = string
  default = 443
}
variable "datastore" { type = string }
variable "vswitch" { type = string }
variable "vlan_id" { type = number }
variable "home_network" { type = string }
variable "okd_network" { type = string }
variable "guest_vm_ssh_user" { type = string }
variable "guest_vm_ssh_port" { type = number }
variable "guest_vm_ssh_passwd" { type = string }
variable "hn_to_ip" {
  type = map
}
variable "hn_to_okdmac" {
  type = map
}

provider "esxi" {
  esxi_hostname = var.my_esxi_hostname
  esxi_hostport = var.my_esxi_hostport
  esxi_hostssl  = var.my_esxi_hostssl
  esxi_username = var.my_esxi_username
  esxi_password = var.my_esxi_password
}

output "guest_multivm-0" {
 value = esxi_guest.multivm[0].ip_address
}

output "guest_multivm-1" {
 value = esxi_guest.multivm[1].ip_address
}

resource "esxi_guest" "multivm" {
  guest_name     = "multivm-${count.index}"
  numvcpus       = "1"
  memsize        = "4096" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"
  # ip_address      = var.hn_to_ip["multivm-0"]
  count          = 2

  network_interfaces {
    virtual_network = var.home_network
    nic_type        = "vmxnet3"
    mac_address     = var.hn_to_okdmac["multivm-${count.index}"]
  }

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = var.guest_vm_ssh_user
      password = var.guest_vm_ssh_passwd
      host  = self.ip_address
    }
    inline = [
      "date | tee -a /tmp/gothere",
      "echo Setting IP address:${var.hn_to_ip["multivm-${count.index}"]} on interface MAC:${var.hn_to_mac["multivm-${count.index}"]} | tee -a /tmp/gothere", 
    ]
  }
}
