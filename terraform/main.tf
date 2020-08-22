# Execution example:
# terraform destroy -auto-approve && terraform plan && \
# terraform apply -auto-approve -target=esxi_guest.okd4-bootstrap
#
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

resource "null_resource" "esxi_network" {
  # These triggers are just a workaround to be able to use variables in the destroy provisioner
  triggers = {
    always_run = "${timestamp()}"
    netname    = var.okd_network
    switch     = var.vswitch
    host       = var.my_esxi_hostname
    user  = var.my_esxi_username
    password = var.my_esxi_password
  }

  # WHY DO YOU MAKE ME PUT THESE IN HERE?!?!?
  connection {
    type  = "ssh"
    user  = "root"
    password = "APassword"
    host  = "esx.lab.linder.org"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Setting up portgroup:${var.okd_network}, on ${var.vswitch}.",
      "esxcli network vswitch standard portgroup add --portgroup-name=${var.okd_network} --vswitch-name=${var.vswitch}",
      "echo Setting up portgroup:${var.okd_network}, on VLAN ${var.vlan_id}.",
      "esxcli network vswitch standard portgroup set -p ${var.okd_network} --vlan-id ${var.vlan_id}",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "echo Destroying up portgroup:${self.triggers.netname}, on ${self.triggers.switch}.",
      # "esxcli network vswitch standard portgroup remove --portgroup-name=${self.triggers.netname} --vswitch-name=${self.triggers.switch}",
    ]
  }
}

provider "esxi" {
  esxi_hostname = var.my_esxi_hostname
  esxi_hostport = var.my_esxi_hostport
  esxi_hostssl  = var.my_esxi_hostssl
  esxi_username = var.my_esxi_username
  esxi_password = var.my_esxi_password
}

output "guest_bootstrap" {
 value = esxi_guest.okd4-bootstrap.ip_address
}

# generate inventory file for Ansible
resource "local_file" "hosts_cfg" {
  # for_each = {
  #   okd4-control-plane-1 = "00:50:56:01:01:02"
  #   okd4-control-plane-2 = "00:50:56:01:01:03"
  #   okd4-control-plane-3 = "00:50:56:01:01:04"
  # }
  content = templatefile("hosts.tpl",
    {
      bootstrap_ip = esxi_guest.okd4-bootstrap.ip_address
      bootstrap_hn = esxi_guest.okd4-bootstrap.guest_name
      # control_ip   = esxi_guest.okd4-control.*.ip_address
      # control_hn   = esxi_guest.okd4-control.*.guest_name
      # services_ip  = esxi_guest.okd4-services.*.ip_address
      # services_hn  = esxi_guest.okd4-services.*.guest_name
      pfsense_ip   = esxi_guest.okd4-pfsense.ip_address
      pfsense_hn   = esxi_guest.okd4-pfsense.guest_name
    }
  )
  filename = "../hosts.cfg"
  depends_on = [
    esxi_guest.okd4-bootstrap,
    esxi_guest.okd4-control,
    esxi_guest.okd4-services,
    esxi_guest.okd4-pfsense
  ]
}

resource "esxi_guest" "okd4-bootstrap" {
  guest_name     = "okd4-bootstrap"
  numvcpus       = "4"
  memsize        = "16384" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  # guestos        = "centos7Guest"      # List: https://code.vmware.com/apis/358/vsphere/doc/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html
  power          = "on"
  virthwver      = "13"

  network_interfaces {
    mac_address     = "00:50:56:01:01:01"
    virtual_network = var.okd_network
    nic_type        = "vmxnet3"
  }

  network_interfaces {
    mac_address     = "00:50:56:01:02:01"
    virtual_network = var.home_network
    nic_type        = "vmxnet3"
  }

  notes = "Built using Terraform"
  clone_from_vm = "/Template-CentOS-8"
  depends_on = [null_resource.esxi_network]

  # provisioner "file" {
  #   connection {
  #     type  = "ssh"
  #     user  = var.ssh_user
  #     password = var.ssh_passwd
  #     host  = self.ip_address
  #   }

  #   source = "script.sh"
  #   destination = "/tmp/script.sh"
  # }

  # provisioner "remote-exec" {
  #   connection {
  #     type  = "ssh"
  #     user  = var.ssh_user
  #     password = var.ssh_passwd
  #     host  = self.ip_address
  #   }

  #   inline = [
  #     "date | tee -a /tmp/gothere",
  #     "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm",
  #     "yum install -y ansible",
  #     "chmod +x /tmp/script.sh",
  #     "/tmp/script.sh",
  #   ]
  # }
}

resource "esxi_guest" "okd4-control" {
  for_each = {
    okd4-control-plane-1 = "00:50:56:01:01:02"
    okd4-control-plane-2 = "00:50:56:01:01:03"
    okd4-control-plane-3 = "00:50:56:01:01:04"
  }
  guest_name     = each.key
  numvcpus       = "4"
  memsize        = "16384" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  # guestos        = "centos7Guest"
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"

  network_interfaces {
    mac_address     = each.value
    virtual_network = var.okd_network
  }

  depends_on = [null_resource.esxi_network]
}

resource "esxi_guest" "okd4-compute" {
  for_each = {
    okd4-compute-1       = "00:50:56:01:01:05"
    okd4-compute-2       = "00:50:56:01:01:06"
  }
  guest_name     = each.key
  numvcpus       = "4"
  memsize        = "16384" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  # guestos        = "centos7Guest"
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"

  network_interfaces {
    mac_address     = each.value
    virtual_network = var.okd_network
  }

  depends_on = [null_resource.esxi_network]
}

resource "esxi_guest" "okd4-services" {
  guest_name     = "okd4-services"
  numvcpus       = "4"
  memsize        = "4096" # in Mb
  boot_disk_size = "100"  # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  # guestos        = "centos7Guest"
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"

  network_interfaces {
    mac_address     = "00:50:56:01:01:07"
    virtual_network = var.okd_network
  }

  network_interfaces {
    mac_address     = "00:50:56:01:01:08"
    virtual_network = var.home_network
  }

  depends_on = [null_resource.esxi_network]
}

resource "esxi_guest" "okd4-pfsense" {
  guest_name     = "okd4-pfsense"
  numvcpus       = "1"
  memsize        = "1024" # in Mb
  boot_disk_size = "8"    # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  guestos        = "freebsd-64"
  power          = "on"
  virthwver      = "13"
  clone_from_vm = "/Template-CentOS-8"

  network_interfaces {
    mac_address     = "00:50:56:01:01:09"
    virtual_network = var.home_network
  }

  network_interfaces {
    mac_address     = "00:50:56:01:01:0A"
    virtual_network = var.okd_network
  }

  depends_on = [null_resource.esxi_network]
}
