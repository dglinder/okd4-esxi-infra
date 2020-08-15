#!/usr/bin/env bash
echo "Running the script" | tee -a /tmp/gothere

# Setup the .ssh directory
mkdir -p ~/.ssh/
chmod 0700 ~/.ssh/
chown root:root ~/.ssh/

# Add the ssh key
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDnvLrwffOBQ6FYCu8NpJ/rDwIfsQSVVHvf3Dk5dqud dan@anssrv' >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
chown root:root ~/.ssh/authorized_keys
