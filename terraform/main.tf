terraform {
  required_version = ">= 0.12"
  required_providers {
    esxi = {
      source  = "josenk/esxi"
      version = "~> 1.7.1"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

resource "null_resource" "esxi_network" {
  # These triggers are just a workaround to be able to use variables in the destroy provisioner
  triggers = {
    always_run = "${timestamp()}"
    netname    = var.okd_network
    switch     = var.vswitch
    host       = var.esxi_host
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
    when = destroy
    inline = [
      "esxcli network vswitch standard portgroup remove --portgroup-name=${self.triggers.netname} --vswitch-name=${self.triggers.switch}",
    ]
  }
}

provider "esxi" {
  esxi_hostname = var.esxi_host
  esxi_hostport = "22"
  esxi_hostssl  = "443"
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

#output "vars" {
#  value = ["${var.esxi_guest}"]
#}

# generate inventory file for Ansible
#resource "local_file" "hosts_cfg" {
#  content = templatefile("${path.module}/hosts.tpl",
#    {
#      #kafka_processors = resources.*.instances.attributes.public_ip
#      #kafka_processors = instances.*.attributes.ip_address
#      #kafka_processors = esxi_guest.ip_address
#      #test_clients = aws_instance.test_client.*.public_ip
#    }
#  )
#  filename = "../hosts.cfg"
#}

resource "esxi_guest" "okd4-bootstrap" {
  guest_name     = "okd4-bootstrap"
  numvcpus       = "4"
  memsize        = "16384" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  guestos        = "fedora-64"
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
  }

  notes = "Built using Terraform"
  clone_from_vm = "/Template-CentOS-8"
  #depends_on = [null_resource.esxi_network]
# }
# 
# resource "null_resource" "remscript" {
  provisioner "file" {
    connection {
      type  = "ssh"
      user  = var.ssh_user
      password = var.ssh_passwd
      host  = "192.168.65.242"
    }

    source = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = var.ssh_user
      password = var.ssh_passwd
      host  = "192.168.65.242"
    }

    inline = [
      "date | tee -a /tmp/gothere",
      "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm",
      "yum install -y ansible",
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh",
    ]
  }
}

resource "esxi_guest" "okd4-machines" {
  for_each = {
    okd4-control-plane-1 = "00:50:56:01:01:02"
    okd4-control-plane-2 = "00:50:56:01:01:03"
    okd4-control-plane-3 = "00:50:56:01:01:04"
    okd4-compute-1       = "00:50:56:01:01:05"
    okd4-compute-2       = "00:50:56:01:01:06"
  }
  guest_name     = each.key
  numvcpus       = "4"
  memsize        = "16384" # in Mb
  boot_disk_size = "120"   # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  guestos        = "fedora-64"
  power          = "off"
  virthwver      = "13"

  network_interfaces {
    mac_address     = each.value
    virtual_network = var.okd_network
  }
  #depends_on = [null_resource.esxi_network]
}

resource "esxi_guest" "okd4-services" {
  guest_name     = "okd4-services"
  numvcpus       = "4"
  memsize        = "4096" # in Mb
  boot_disk_size = "100"  # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  guestos        = "centos-64"
  power          = "off"
  virthwver      = "13"

  network_interfaces {
    mac_address     = "00:50:56:01:01:07"
    virtual_network = var.okd_network
  }

  network_interfaces {
    mac_address     = "00:50:56:01:01:08"
    virtual_network = var.home_network
  }

  #depends_on = [null_resource.esxi_network]
}

resource "esxi_guest" "okd4-pfsense" {
  guest_name     = "okd4-pfsense"
  numvcpus       = "1"
  memsize        = "1024" # in Mb
  boot_disk_size = "8"    # in Gb
  boot_disk_type = "thin"
  disk_store     = var.datastore
  guestos        = "freebsd-64"
  power          = "off"
  virthwver      = "13"

  network_interfaces {
    mac_address     = "00:50:56:01:01:09"
    virtual_network = var.home_network
  }

  network_interfaces {
    mac_address     = "00:50:56:01:01:0A"
    virtual_network = var.okd_network
  }

  #depends_on = [null_resource.esxi_network]
}
