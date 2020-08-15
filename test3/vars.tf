variable "esxi_host" {
    default = "esx.lab.linder.org"
}

variable "esxi_username" {
    default = "root"
}

variable "esxi_password" {
    default = "APassword"
}

variable "datastore" {
   default = "datastore1" 
}
variable "vlan_id" {
    default = "20"
}

variable "vswitch" {
    default = "vSwitch0"
}

variable "home_network" {
    default = "VM Network"
}
variable "okd_network" {
    default = "OKD"
}
