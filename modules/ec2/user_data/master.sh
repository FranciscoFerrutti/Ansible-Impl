#!/bin/bash

# Redirect output to log file for debugging
exec > >(tee -a /var/log/user-data.log) 2>&1
echo "Starting AWX installation at $(date)"

# Set variables
AWX_VERSION="2.4.0"
NAMESPACE="awx"
LOG_FILE="/var/log/awx-install.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Update and upgrade system
log "Updating system packages"
sudo apt update -y && sudo apt upgrade -y || { log "Failed to update system"; exit 1; }

# Install dependencies
log "Installing Docker, make, curl, and git"
sudo apt install -y docker.io make curl git || { log "Failed to install dependencies"; exit 1; }

# Install Minikube
log "Installing Minikube"
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 || { log "Failed to download Minikube"; exit 1; }
sudo install minikube-linux-amd64 /usr/local/bin/minikube || { log "Failed to install Minikube"; exit 1; }
rm minikube-linux-amd64

