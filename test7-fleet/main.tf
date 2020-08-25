# Fleet
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
variable "hn_to_ip" { type = map }
variable "hn_to_okdmac" { type = map }
variable "hn_to_nm" { type = map }
variable "hn_to_gw" { type = map }

provider "esxi" {
  esxi_hostname = var.my_esxi_hostname
  esxi_hostport = var.my_esxi_hostport
  esxi_hostssl  = var.my_esxi_hostssl
  esxi_username = var.my_esxi_username
  esxi_password = var.my_esxi_password
}

resource "esxi_guest" "okd4-bootstrap" {
  guest_name     = "okd4-bootstrap"
  numvcpus       = "1"
  memsize        = "4096" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"
  guestinfo      = {
    metadata = "okd4-bootstrap_group"
  }

  network_interfaces {
    mac_address     = var.hn_to_okdmac["okd4-bootstrap"]
    virtual_network = var.home_network
    nic_type        = "vmxnet3"
    # NOTE: the ipv4_address/_gateway are not supported with esxi.
    # Use the CloudInit or other options documented here:
    #   https://github.com/josenk/terraform-provider-esxi-wiki
  }

  provisioner "file" {
    connection {
      type  = "ssh"
      user  = var.guest_vm_ssh_user
      password = var.guest_vm_ssh_passwd
      host  = self.ip_address
    }
    source = "setup_ip.sh"
    destination = "/root/setup_ip.sh"
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
      "echo Setting IP address:${var.hn_to_ip["okd4-bootstrap"]} on interface MAC:${var.hn_to_okdmac["okd4-bootstrap"]} | tee -a /tmp/gothere", 
      "/usr/bin/hostnamectl set-hostname okd4-bootstrap",
      "chmod +x /root/setup_ip.sh",
      "/root/setup_ip.sh ${var.hn_to_okdmac["okd4-bootstrap"]} ${var.hn_to_ip["okd4-bootstrap"]} 24 192.168.65.1 | tee -a /tmp/gothere",
    ]
  }
}

resource "esxi_guest" "okd4-services" {
  guest_name     = "okd4-services"
  numvcpus       = "1"
  memsize        = "4096" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"
  guestinfo      = {
    metadata = "okd4-services_group"
  }

  network_interfaces {
    mac_address     = var.hn_to_okdmac["okd4-services"] #"00:50:56:01:01:01"
    virtual_network = var.home_network
    nic_type        = "vmxnet3"
  }
}

resource "esxi_guest" "okd4-pfsense" {
  guest_name     = "okd4-pfsense"
  numvcpus       = "1"
  memsize        = "4096" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"
  guestinfo      = {
    metadata = "okd4-pfsense_group"
  }

  network_interfaces {
    mac_address     = var.hn_to_okdmac["okd4-pfsense"] #"00:50:56:01:01:01"
    virtual_network = var.home_network
    nic_type        = "vmxnet3"
  }
}

resource "esxi_guest" "okd4-control-plane" {
  guest_name     = "okd4-control-plane-${count.index}"
  numvcpus       = "1"
  memsize        = "4096" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"
  count          = 3
  guestinfo      = {
    metadata = "okd4-control-plane_group"
  }

  network_interfaces {
    virtual_network = var.home_network
    nic_type        = "vmxnet3"
    mac_address     = var.hn_to_okdmac["okd4-control-plane-${count.index}"]
  }

  provisioner "file" {
    connection {
      type  = "ssh"
      user  = var.guest_vm_ssh_user
      password = var.guest_vm_ssh_passwd
      host  = self.ip_address
    }
    source = "setup_ip.sh"
    destination = "/root/setup_ip.sh"
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
      "echo Setting IP address:${var.hn_to_ip["okd4-control-plane-${count.index}"]} on interface MAC:${var.hn_to_okdmac["okd4-control-plane-${count.index}"]} | tee -a /tmp/gothere", 
      "chmod +x /root/setup_ip.sh",
      "/root/setup_ip.sh ${var.hn_to_okdmac["okd4-control-plane-${count.index}"]} ${var.hn_to_ip["okd4-control-plane-${count.index}"]} 24 192.168.65.1 | tee -a /tmp/gothere",
      "sleep 30",
    ]
  }
}

resource "esxi_guest" "okd4-compute" {
  guest_name     = "okd4-compute-${count.index}"
  numvcpus       = "1"
  memsize        = "4096" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"
  count          = 2
  # guestinfo      = {
  #   metadata = "okd4-compute_group"
  # }

  network_interfaces {
    virtual_network = var.home_network
    nic_type        = "vmxnet3"
    mac_address     = var.hn_to_okdmac["okd4-compute-${count.index}"]
  }

  # provisioner "file" {
    # connection {
      # type  = "ssh"
      # user  = var.guest_vm_ssh_user
      # password = var.guest_vm_ssh_passwd
      # host  = self.ip_address
    # }
    # source = "setup_ip.sh"
    # destination = "/root/setup_ip.sh"
  # }
# 
  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = var.guest_vm_ssh_user
      password = var.guest_vm_ssh_passwd
      host  = self.ip_address
    }
    inline = [
      "date | tee -a /tmp/gothere",
      "echo Setting IP address:${var.hn_to_ip["okd4-control-plane-${count.index}"]} on interface MAC:${var.hn_to_okdmac["okd4-control-plane-${count.index}"]} | tee -a /tmp/gothere", 
      # "chmod +x /root/setup_ip.sh",
      # "/root/setup_ip.sh ${var.hn_to_okdmac["okd4-control-plane-${count.index}"]} ${var.hn_to_ip["okd4-control-plane-${count.index}"]} 24 192.168.65.1 | tee -a /tmp/gothere",
      # "sleep 30",   # So Terraform will have time to get the IP address
    ]
  }
}

resource "local_file" "AnsibleInventory" {
 content = templatefile("hosts.tpl",
 {
  okd4-bootstrap-dns     = esxi_guest.okd4-bootstrap.guest_name,
  okd4-bootstrap-ip      = esxi_guest.okd4-bootstrap.ip_address,
  okd4-bootstrap-id      = esxi_guest.okd4-bootstrap.id,

  okd4-services-dns      = esxi_guest.okd4-services.guest_name,
  okd4-services-ip       = esxi_guest.okd4-services.ip_address,
  okd4-services-id       = esxi_guest.okd4-services.id,

  okd4-pfsense-dns       = esxi_guest.okd4-pfsense.guest_name,
  okd4-pfsense-ip        = esxi_guest.okd4-pfsense.ip_address,
  okd4-pfsense-id        = esxi_guest.okd4-pfsense.id,

  okd4-control-plane-dns = esxi_guest.okd4-control-plane.*.guest_name,
  okd4-control-plane-ip  = esxi_guest.okd4-control-plane.*.ip_address,
  okd4-control-plane-id  = esxi_guest.okd4-control-plane.*.id

  okd4-compute-dns       = esxi_guest.okd4-compute.*.guest_name,
  okd4-compute-ip        = esxi_guest.okd4-compute.*.ip_address,
  okd4-compute-id        = esxi_guest.okd4-compute.*.id
 }
 )
 filename = "inventory"
}
