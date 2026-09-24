#!/bin/bash
set -euo pipefail

# Docker installation script
echo "========================================="
echo "Starting Docker installation"
echo "========================================="

# Update packages (if not done earlier)
apt update

# Add the Docker GPG key
# Remove the old key before import so re-runs do not fail
rm -f /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL --max-time 30 --retry 2 https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add the Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable Docker autostart
systemctl enable docker
systemctl start docker

# Add the real user (not root) to the docker group
# When run via sudo, take the original username from SUDO_USER
TARGET_USER="${SUDO_USER:-$USER}"
if [ -n "${TARGET_USER}" ] && [ "${TARGET_USER}" != "root" ]; then
    usermod -aG docker "${TARGET_USER}"
    echo "User ${TARGET_USER} added to the docker group"
    echo "(log out and log back in for the change to take effect)"
fi

echo "========================================="
echo "Docker installation completed"
echo "========================================="

# Verify installation
docker --version
docker ps

echo "Docker installed successfully!"