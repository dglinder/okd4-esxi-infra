terraform {
  required_version = ">= 0.12"
  required_providers {
    esxi = {
      source  = "registry.terraform.io/josenk/esxi"
      version = "~> 1.7.1"
    }
  }
}

provider "esxi" {
  esxi_hostname      = "esx.lab.linder.org"
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = "root"
  esxi_password      = "APassword"
}

resource "esxi_guest" "vmtest" {
  guest_name         = "vmtest"
  disk_store         = "datastore1"

  #
  #  Specify an existing guest to clone, an ovf source, or neither to build a bare-metal guest vm.
  #
  #clone_from_vm      = "Templates/centos7"
  #ovf_source        = "/local_path/centos-7.vmx"

  network_interfaces {
    virtual_network = "VM Network"
  }
}
