terraform {
  required_version = ">= 0.12"
}

provider "esxi" {
  esxi_hostname      = "esx.lab.linder.org"
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = "root"
  esxi_password      = "APassword"
}

resource "null_resource" "esxi_network" {
  provisioner "remote-exec" {
    inline = [
      "whoami > /tmp/test.out",
    ]
  }
}

resource "esxi_guest" "vmtest" {
  guest_name         = "vmtest"
  disk_store         = "datastore1"
  network_interfaces {
    virtual_network = "VM Network"
  }
}
