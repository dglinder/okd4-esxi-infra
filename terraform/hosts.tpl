# Ideas from:
# https://medium.com/@moep_moep/terraform-to-create-ansible-inverntory-8c4e2a530890
[bootstrap]
${bootstrap_hn} ansible_host=${bootstrap_ip}

[pfsense_host]
${pfsense_hn} ansible_host=${pfsense_ip}

[service_host]
${services_hn} ansible_host=${services_ip}

[control]
${control_hn} ansible_host=${control_ip}
