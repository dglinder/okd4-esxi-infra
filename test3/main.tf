terraform {
  required_version = ">= 0.12"
  required_providers {
    esxi = {
      version = "~> 1.7"
    }
  }
}

resource "null_resource" "esxi_network" {
  # These triggers are just a workaround to be able to use variables in the destroy provisioner
  triggers = {
    always_run = "${timestamp()}"
    netname = var.okd_network
    switch  = var.vswitch
    host    = var.esxi_host
  }

  connection {
    host = self.triggers.host
  }

  provisioner "remote-exec" {
    inline = [
      "esxcli network vswitch standard portgroup add --portgroup-name=${var.okd_network} --vswitch-name=${var.vswitch}",
      "esxcli network vswitch standard portgroup set -p ${var.okd_network} --vlan-id ${var.vlan_id}",
    ]
  }

  provisioner "remote-exec" {
    when    = destroy
    inline = [
      "esxcli network vswitch standard portgroup remove --portgroup-name=${self.triggers.netname} --vswitch-name=${self.triggers.switch}",
    ]
  }
}

provider "esxi" {
  esxi_hostname      = var.esxi_host
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = var.esxi_username
  esxi_password      = var.esxi_password
}

resource "esxi_guest" "GH-okd4-bootstrap" {
  guest_name     = "GH-okd4-bootstrap"
  numvcpus       = "4"
  memsize        = "16384"  # in Mb
  boot_disk_size = "120" # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  guestos        = "fedora-64"
  power          = "off"
  virthwver      = "13"

  network_interfaces {
    mac_address     = "00:50:56:02:01:01"
    virtual_network = var.okd_network
  }
  depends_on = [null_resource.esxi_network]
}
