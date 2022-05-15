#!/bin/bash

# Bootstrap Debian base VMs.
set -euxo pipefail

# Get current hostname
declare -r VM_HOSTNAME="$(hostname -s)"

# Refresh repository list
apt-get update

# Install packages.
apt-get install -y htop curl wget dnsutils vim apt-transport-https net-tools jq nmap

# Remove duplicate name entry on /etc/hosts
sed -i '/127.0.1.1 '${VM_HOSTNAME}'/d' /etc/hosts
