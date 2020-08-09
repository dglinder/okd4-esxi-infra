#!/bin/sh
set -x

export VAR_OKD_NETWORK="OKD"
export VAR_VSWITCH="vSwitch0"
export VAR_VLAN_ID=20

echo Executing with portgroup-name=$VAR_OKD_NETWORK
echo Executing with vswitch-name=$VAR_VSWITCH
esxcli network vswitch standard portgroup remove --portgroup-name=$VAR_OKD_NETWORK --vswitch-name=$VAR_VSWITCH
echo EC-remove:$?

