#!/usr/bin/env bash
terraform show --json | jq '.values.root_module.resources[].values | {hostname: .guest_name, ipaddr: .ip_address}'

