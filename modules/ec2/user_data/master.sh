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

# Configure Docker group
log "Configuring Docker for ubuntu user"
sudo usermod -aG docker ubuntu || { log "Failed to add ubuntu to docker group"; exit 1; }
sudo systemctl enable docker
sudo systemctl start docker

# Switch to ubuntu user for subsequent commands
log "Switching to ubuntu user for AWX setup"
sudo -u ubuntu bash << EOF

# Set variables
AWX_VERSION="2.4.0"
NAMESPACE="awx"
HOME_DIR="/home/ubuntu"
LOG_FILE="/var/log/awx-install.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Clone AWX Operator
log "Cloning AWX Operator repository"
cd "$HOME_DIR"
git clone https://github.com/ansible/awx-operator.git || { log "Failed to clone AWX Operator"; exit 1; }
cd awx-operator
git checkout tags/"$AWX_VERSION" || { log "Failed to checkout AWX version $AWX_VERSION"; exit 1; }

# Create kustomization.yml
log "Creating kustomization.yml"
cat > kustomization.yml << KUSTOMIZE
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.4.0
  - awx-demo.yml
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.4.0
namespace: awx
KUSTOMIZE
[ $? -eq 0 ] || { log "Failed to create kustomization.yml"; exit 1; }

# Create awx-demo.yml
log "Creating awx-demo.yml"
cat > awx-demo.yml << AWX_DEMO
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
AWX_DEMO
[ $? -eq 0 ] || { log "Failed to create awx-demo.yml"; exit 1; }

# Start Minikube
log "Starting Minikube"
minikube start --cpus=2 --memory=6g --addons=ingress --driver=docker || { log "Failed to start Minikube"; exit 1; }

# Alias kubectl
alias kubectl="minikube kubectl --"

# Verify Minikube
log "Verifying Minikube nodes"
kubectl get nodes | grep -q "minikube.*Ready" || { log "Minikube node not ready"; exit 1; }

# Apply AWX Operator and AWX DEMO
log "Applying AWX Operator"
kubectl apply -k . || { log "Failed to apply AWX Operator"; exit 1; }
log "Applying AWX DEMO"
kubectl apply -f awx-demo.yml || { log "Failed to apply AWX DEMO"; exit 1; }

# Wait for AWX pods to be running
log "Waiting for AWX pods to be running"
for i in {1..30}; do
    if kubectl get pods -n "$NAMESPACE" | grep -E "awx-demo-(web|task)" | grep -q "Running"; then
        log "AWX pods are running"
        break
    fi
    log "Waiting for AWX pods... ($i/30)"
    sleep 30
done
kubectl get pods -n "$NAMESPACE" | grep -E "awx-demo-(web|task)" | grep -q "Running" || { log "AWX pods not running after 15 minutes"; exit 1; }

# Set up port forwarding in background
log "Setting up port forwarding to 0.0.0.0:80"
nohup kubectl port-forward svc/awx-demo-service -n "$NAMESPACE" 80:80 --address 0.0.0.0 >> "$LOG_FILE" 2>&1 &

EOF

log "AWX installation completed at $(date)"