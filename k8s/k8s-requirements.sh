#!/bin/bash

# Ensure overlay and br_netfilter modules are loaded at startup
echo -e "Ensure overlay and br_netfilter modules are loaded at startup."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Ensure br_netfilter is loaded
if lsmod | grep -q br_netfilter;
then
	echo -e "Load br_netfilter."
	sudo modprobe br_netfilter
fi

# Ensure overlay is loaded
if lsmod | grep -q overlay;
then
	echo -e "Load overlay."
	sudo modprobe overlay
fi

# Setup birdge
echo -e "Setup bridge and ip forwarding."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# Install container runtime
echo -e "Install containerd runtime."
sudo apt-get install -y containerd

# Get pyblic GPG key for apt.kubernetes.io repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

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

