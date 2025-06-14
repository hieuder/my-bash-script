#!/bin/bash

# Script to install Docker and Docker Compose, create docker-compose.yaml, and run the service.

# --- 1. Install Docker ---
echo "--- Installing Docker and Docker Compose ---"

# Update package lists
sudo apt-get update -y

# Install necessary packages for apt to use a repository over HTTPS
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the stable Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package lists again after adding Docker repository
sudo apt-get update -y

# Install Docker Engine, CLI, Containerd, and Docker Compose Plugin
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- 2. Add current user to the docker group ---
# This allows running docker commands without sudo.
# Note: You will need to log out and log back in (or reboot) for this change to take effect fully
# for commands run outside this script. This script runs as root, so it's not strictly necessary for it.
echo "--- Adding current user to the docker group ---"
sudo usermod -aG docker "${USER}"

# --- 3. Create docker-compose.yaml file ---
echo "--- Creating docker-compose.yaml ---"
cat <<EOF > docker-compose.yaml
services:
  windowz:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "https://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO"
    ports:
      - "8006:8006" # Maps host port 8006 to container port 8006
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/kvm:/dev/kvm
EOF

echo "docker-compose.yaml created successfully."

# --- 4. Run docker-compose up ---
echo "--- Running docker-compose up ---"
# Use 'sudo' here just in case the group change hasn't taken effect or if not logged in as the target user.
sudo docker-compose up

echo "Script finished. Check http://localhost:8006/ in your browser after Windows starts."
