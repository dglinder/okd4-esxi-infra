[kafka_broker_hosts]
%{ for ip in kafka_processors ~}
${ip}
%{ endfor ~}

#[test_client_hosts]
#%{ for ip in test_clients ~}
#${ip}
#%{ endfor ~}
