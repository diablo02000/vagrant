#!/bin/bash
#
# Setup for workers nodes

set -euxo pipefail

# Get current hostname
declare -r VM_HOSTNAME="$(hostname -s)"

# Define path to shared folder
declare -r ROOT_SHARED_FOLDER="/vagrant/k8s-config"

# Define vagrant home directory
declare -r VAGRANT_HOME_DIR="/home/vagrant"

# Join worker to master node.
/bin/bash "${ROOT_SHARED_FOLDER}/worker-join.sh"

# Setup credential configuration for vagrant user
sudo -i -u vagrant bash <<EOF
mkdir -p ${VAGRANT_HOME_DIR}/.kube
sudo cp -i ${ROOT_SHARED_FOLDER}/config ${VAGRANT_HOME_DIR}/.kube/config
sudo chown 1000:1000 ${VAGRANT_HOME_DIR}/.kube/config
EOF

# Update label for kubernetes worker
sudo -i -u vagrant kubectl label node "${VM_HOSTNAME}" node-role.kubernetes.io/worker=worker
