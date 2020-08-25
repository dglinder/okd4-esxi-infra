[servers]
%{ for index, dns in multivm-dns ~}
${dns} ansible_host=${multivm-ip[index]} # ${multivm-id[index]}
%{ endfor ~}
