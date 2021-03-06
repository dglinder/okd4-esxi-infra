#!/bin/bash
# Call with MAC ADDR ADDR_NM GWADDR on command line

# The output is logged to the file in ${LOGFILE}.  A .1/.2/.3 is appended
# to each file for the different output areas so they don't overwrite each
# other.
LOGFILE="/tmp/gothere"

# Capture all script output
exec >> ${LOGFILE}.1 2>&1

echo "Script datestamp: Wed Aug 26 18:09:42 UTC 2020"

MAC="$1"
ADDR="$2"
ADDR_NM="$3"
GWADDR="$4"

#set -x
set -e
set -u
if [[ "${MAC}" == "" || "${ADDR}" == "" || "${ADDR_NM}" == "" || "${GWADDR}" == "" ]] ; then
  echo Missing a command line variable.
  echo "MAC:     >>${MAC}<<"
  echo "ADDR:    >>${ADDR}<<"
  echo "ADDR_NM: >>${ADDR_NM}<<"
  echo "GWADDR:  >>${GWADDR}<<"
  exit 1
fi

echo "Setting NIC with MAC address: ${MAC}"

# Get the IF name from the MAC address we know
IFNAME=$(nmcli | egrep "^[a-z]|${MAC}" | egrep -B1 "${MAC}" | egrep -v "${MAC}" | cut -d: -f 1)

echo "Found NIC: ${IFNAME}"

echo "Setting ${IFNAME} to ${ADDR}/${ADDR_NM}, default gw ${GWADDR}"

# Set the address
echo "Setting address and netmask: ${ADDR}/${ADDR_NM}"
nmcli con mod ${IFNAME} ipv4.address ${ADDR}/${ADDR_NM}

# Set the gateway
echo "Setting gateway: ${GWADDR}"
nmcli con mod ${IFNAME} ipv4.gateway ${GWADDR}

# Set to manual IPv4 (not DHCP)
echo "Setting manual IP addressing"
nmcli con mod ${IFNAME} ipv4.method manual

# Set to autostart
echo "Setting NIC to autoconnect"
nmcli con mod ${IFNAME} autoconnect yes

# Restart the interface in the background
# so Terraform can exit cleanly
(
  # Capture all script output
  exec >> ${LOGFILE}.2 2>&1
  sleep 1
  echo "$(date) - #######################################"
  echo "$(date) - Waiting 30 seconds to restart NIC"
  sleep 30
  echo "$(date) - Down-ing ${IFNAME}"
  nmcli con down ${IFNAME}
  sleep 1
  echo "$(date) - Up-ing ${IFNAME}"
  nmcli con up ${IFNAME}
  echo "$(date) - NIC ${IFNAME} status: $(ip ad sh ${IFNAME})"
  echo "$(date) - #######################################"
) 2>&1 | tee -a ${LOGFILE}.3 &
# disown

sleep 5
echo "$(date) - Exiting script"
exit 0
