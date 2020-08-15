variable "esxi_host" {
    default = "esx.lab.linder.org"
}

variable "esxi_username" {
    type    = string
    default = "root"
}

variable "esxi_password" {
    type    = string
    default = "q7-19ezx"
}

variable "datastore" {
    type    = string
   default = "datastore1" 
}
variable "vlan_id" {
    type    = number
    default = 20
}

variable "vswitch" {
    type    = string
    default = "vSwitch0"
}

variable "home_network" {
    type    = string
    default = "VM Network"
}

variable "okd_network" {
    type    = string
    default = "OKD"
}

variable "ssh_user" {
    type    = string
    default = "root"
}

variable "ssh_port" {
    type    = number
    default = 22
}
variable "ssh_passwd" {
    type    = string
    default = "APassword"
}
