#!/bin/bash

# Setup Kubernetes requirements. 
set -euxo pipefail

# Define OS use.
declare -r OS="Debian_10"

# Define cri-o version to install
declare -r CRIO_VERSION="1.23"

########
# Swap #
########
# Disable swap
sudo swapoff -a
# Disable swap after reboot
sudo sed -i '/ swap / s/^/#/' /etc/fstab

##################
# Kernel Modules #
##################
# Ensure overlay and br_netfilter modules are loaded after reboot
echo -e "Ensure overlay and br_netfilter modules are loaded at startup."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Load br_netfilter if not loaded
if ! lsmod | grep -q br_netfilter;
then
	echo -e "Load br_netfilter."
	sudo modprobe br_netfilter
fi

# Load overlay if not loaded
if ! lsmod | grep -q overlay;
then
	echo -e "Load overlay."
	sudo modprobe overlay
fi

###########
# Network #
###########
# Setup bridge and ip forward.
echo -e "Setup bridge and ip forwarding."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
# Reload sys config
sudo sysctl --system

#####################
# Container runtime #
#####################
# Add cri-o repository
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /
EOF

# Add cri-o GPG key is not present on /vagrant share
if [[ ! -f /vagrant/libcontainers-crio-archive-keyring.gpg ]];
then	
	curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo gpg --batch --dearmor -o /etc/apt/trusted.gpg.d/libcontainers-crio-archive-keyring.gpg
	curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --batch --dearmor -o /etc/apt/trusted.gpg.d/libcontainers-archive-keyring.gpg
	cp /etc/apt/trusted.gpg.d/libcontainers-crio-archive-keyring.gpg /vagrant/libcontainers-crio-archive-keyring.gpg
	cp /etc/apt/trusted.gpg.d/libcontainers-archive-keyring.gpg /vagrant/libcontainers-archive-keyring.gpg
else
	cat /vagrant/libcontainers-crio-archive-keyring.gpg | sudo gpg --batch --dearmor -o /etc/apt/trusted.gpg.d/libcontainers-crio-archive-keyring.gpg
	cat /vagrant/libcontainers-archive-keyring.gpg | sudo gpg --batch --dearmor -o /etc/apt/trusted.gpg.d/libcontainers-archive-keyring.gpg
fi

# Refresh repository
sudo apt-get update

# Install cri-o and crio-tools
apt-get install -y cri-o cri-o-runc cri-tools

# Ensure cri-o service is enabled and started
sudo systemctl enable crio.service
sudo systemctl start crio.service

##############
# Kubernetes #
##############
# Get public GPG key for apt.kubernetes.io repository
if [[ ! -f /vagrant/kubernetes.gpg ]];
then
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --batch --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
	cp /etc/apt/trusted.gpg.d/kubernetes.gpg /vagrant/kubernetes.gpg
else
	cat /vagrant/kubernetes.gpg | sudo gpg --batch --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
fi

# Add kubernetes repository configuration
echo -e "Add apt.kubernetes.io repository."
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Refresh repository update list
sudo apt-get update

# Install kubeadm
echo -e "Install k8s administration tool."
sudo apt-get install -y kubelet kubeadm kubectl
