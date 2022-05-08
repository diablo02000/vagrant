#!/bin/bash

# Refresh repository list
apt-get update

# Install packages.
apt-get install -y htop curl wget dnsutils vim apt-transport-https
