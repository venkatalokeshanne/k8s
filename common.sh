#!/bin/bash

# Set Kubernetes version (ensure correct version format)
KUBERNETES_VERSION="1.30.0-00"

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Disable swap (required for Kubernetes)
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab # Ensure swap is disabled on boot

# Load kernel modules
echo "Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters for Kubernetes networking
echo "Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Install containerd
echo "Installing containerd..."
sudo apt install -y containerd

# Configure containerd
echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes APT repository
echo "Adding Kubernetes APT repository..."
sudo apt install -y apt-transport-https ca-certificates curl
sudo mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubeadm, kubelet, and kubectl
echo "Installing Kubernetes components..."
sudo apt update
sudo apt install -y kubelet="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION"
sudo apt-mark hold kubelet kubeadm kubectl

echo "Kubernetes setup completed successfully!"
