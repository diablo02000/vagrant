#!/usr/bin/env bash

declare -ra APT_PKG_LIST=("make" "build-essential" "git" "curl" "dkms" "clang" "llvm" "gpg" "linux-headers-$(uname -r)")

declare -r GOLANG_VERSION="1.20.4"
declare -r GOLANG_ARCHIVE_NAME="go${GOLANG_VERSION}.linux-amd64.tar.gz"
declare -r GOLANG_URL="https://go.dev/dl/${GOLANG_ARCHIVE_NAME}"

declare -r FALCO_PUBLIC_GPG="https://falco.org/repo/falcosecurity-packages.asc"
declare -r KEYRING_FALCO_GPG_PATH="/usr/share/keyrings/falco-archive-keyring.gpg"
declare -r FALCO_APT_REPOSITORY="https://download.falco.org/packages/deb"

# Disable interaction during apt command
export DEBIAN_FRONTEND="noninteractive"

# Upgrade OS
apt-get update && apt-get upgrade -y

# Install required package
echo -e " >>>>> ${APT_PKG_LIST[@]}"
apt-get install -y ${APT_PKG_LIST[@]}

# Install golang
curl -fsSL "${GOLANG_URL}" -o "/tmp/${GOLANG_ARCHIVE_NAME}"
tar -C /usr/local -xzf "/tmp/${GOLANG_ARCHIVE_NAME}"

# Add Golang bin in PATH
for i in "/home/vagrant" "/root"
do
  echo 'export PATH=$PATH:/usr/local/go/bin' >> "${i}/.profile"
done

source "${HOME}/.profile"
go version

# Deploy Falco public gpg
curl -fsSL "${FALCO_PUBLIC_GPG}" | gpg --dearmor -o "${KEYRING_FALCO_GPG_PATH}"
echo "deb [signed-by=${KEYRING_FALCO_GPG_PATH}] ${FALCO_APT_REPOSITORY} stable main" | tee -a /etc/apt/sources.list.d/falcosecurity.list

# Install falco
apt update && apt install -y falco

# Install ebpf Falco driver
falco-driver-loader bpf

# Enable and start Falco service
systemctl enable falco-bpf.service
systemctl stop falcoctl-artifact-follow.service
systemctl start falco-bpf.service


