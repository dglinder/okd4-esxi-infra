[bootstrap]
%{ for ip in bootstrap_ip ~}
${ip}
%{ endfor ~}

[control_hosts]
%{ for ip in control_ip ~}
${ip}
%{ endfor ~}

[services_hosts]
%{ for ip in services_ip ~}
${ip}
%{ endfor ~}

[pfsense_hosts]
%{ for ip in pfsense_ip ~}
${ip}
%{ endfor ~}
