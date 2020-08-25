my_esxi_hostname = "esx.lab.linder.org"
my_esxi_username = "root"
my_esxi_password = "1234NewS!@#$"

datastore = "datastore1" 
vlan_id = 20
vswitch = "vSwitch0"
home_network = "VM Network"
okd_network = "OKD"

guest_vm_ssh_user = "root"
guest_vm_ssh_port = 22
guest_vm_ssh_passwd = "123NewS!@#"

hn_to_ip = {
    okd4-bootstrap       = "192.168.1.200"
    okd4-control-plane-1 = "192.168.1.201"
    okd4-control-plane-2 = "192.168.1.202"
    okd4-control-plane-3 = "192.168.1.203"
    okd4-compute-1       = "192.168.1.204"
    okd4-compute-2       = "192.168.1.205"
    okd4-services        = "192.168.1.210"
    okd4-pfsense         = "192.168.1.1"
  }
