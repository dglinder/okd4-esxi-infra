# Setup VM template with Cloud-Init

Reference URLs:
  - https://docs.kublr.com/installation/vmware/vsphere_centos7_cloud-init/
  - https://github.com/vmware/cloud-init-vmware-guestinfo
  - https://devops.ionos.com/tutorials/deploy-a-centos-server-customized-with-cloud-init/
  - https://blogs.vmware.com/management/2019/03/build-a-cloud-automation-service-ready-centos-template.html
  - https://blogs.vmware.com/management/2019/03/build-a-cloud-automation-service-ready-centos-template.html
  - https://knotacoder.com/2019/08/22/centos-image-for-cloud-init-on-vmware-cloud-assembly-services/
  - https://access.redhat.com/documentation/en-us/red_hat_enterprise_virtualization/3.6/html/virtual_machine_management_guide/sect-using_cloud-init_to_automate_the_configuration_of_virtual_machines
  - 

Requires: Centos / RHEL 7
Packages: perl python3-pip cloud-init git python36 open-vm-tools curl

# Steps

1. Install "Minimal server"
1. Login as root and update system
  * `yum -y update`
1. Enable password login
  * `vi /etc/ssh/sshd_config`
  * Set the `PasswordAuthentication` to `yes`
1. Install the Cloud-Init core components and reboot
  * `yum -y install perl python3-pip cloud-init git python36 open-vm-tools curl`
  * `reboot`
1. Ensure system comes up as expected
1. Prep system for templating
  * `cloud-init clean`
  * `poweroff`

