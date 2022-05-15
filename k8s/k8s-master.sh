#!/bin/bash

# Setup Kubernetes requirements. 
set -euxo pipefail

# Get IPV4 master ip
declare -r MASTER_IP="$(ip -j -o -4 addr list eth0 | jq -r '.[].addr_info[].local')"

# Get current hostname
declare -r HOSTNAME="$(hostname -s)"

# Define POD CIDR
declare -r POD_CIDR="172.16.0.0/16"

# Define path to shared folder
declare -r ROOT_SHARED_FOLDER="/vagrant/k8s-config"

# Define Kubernetes dashboard version
declare -r K8S_DASHBOARD_VERSION="v2.5.1"

# Init k8s master
sudo kubeadm init --apiserver-advertise-address="${MASTER_IP}" --apiserver-cert-extra-sans="${MASTER_IP}" --pod-network-cidr="${POD_CIDR}" --node-name "${HOSTNAME}"

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Remove older config shared folder
if [[ -d "${ROOT_SHARED_FOLDER}" ]];
then
	rm -rf "${ROOT_SHARED_FOLDER}"
	mkdir "${ROOT_SHARED_FOLDER}"
else
	# Ensure shared folder config exists
	mkdir "${ROOT_SHARED_FOLDER}"
fi

# Store k8s connection configuration file.
cp "$HOME"/.kube/config "${ROOT_SHARED_FOLDER}/config"

# Get join command and store in shared folder
kubeadm token create --print-join-command > "${ROOT_SHARED_FOLDER}/worker-join.sh"

# Install network plugin (Calico)

# Create k8s calico operator
kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml

# Download custom resources manifest
curl -Ls -o calico-custom-resources.yaml https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml

# Update IPV4 pool
sed -i 's#192.168.0.0/16#'"${POD_CIDR}"'#g' calico-custom-resources.yaml

# Deploy Calico
kubectl apply -f calico-custom-resources.yaml

# Install metrics server (Required for k8s dashboard)
kubectl apply -f https://raw.githubusercontent.com/scriptcamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# Deploy K8s dashboard
kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/${K8S_DASHBOARD_VERSION}/aio/deploy/recommended.yaml"

# Create dashboard user
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Get dashboard user tolen
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" >  "${ROOT_SHARED_FOLDER}/dashboard-token"

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF
