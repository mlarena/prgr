#!/bin/bash
set -euo pipefail

# Load shared functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Automatic IP address detection
SERVER_IP=$(detect_server_ip)
echo "========================================="
echo "Preliminary tool installation"
echo "Server IP address: ${SERVER_IP}"
echo "========================================="

# Update packages
apt update && apt upgrade -y

# Install required utilities
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    wget \
    lsb-release \
    net-tools \
    jq \
    git \
    vim \
    iproute2 \
    sudo \
    nload \
    iftop

echo "========================================="
echo "Preliminary installation completed"
echo "========================================="