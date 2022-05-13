#!/bin/bash

# Bootstrap Debian base VMs.
set -euxo pipefail

# Refresh repository list
apt-get update

# Install packages.
apt-get install -y htop curl wget dnsutils vim apt-transport-https net-tools jq
