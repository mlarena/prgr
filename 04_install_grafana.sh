#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)

echo "========================================="
echo "Installing Grafana"
echo "Server IP address: ${SERVER_IP}"
echo "========================================="

# Stop and remove the old container if it exists
docker stop grafana 2>/dev/null || true
docker rm grafana 2>/dev/null || true

# Pull the Grafana image (docker pull is idempotent)
echo "Pulling Grafana image..."
docker pull grafana/grafana

# Run Grafana in Docker
# GF_SECURITY_ADMIN_PASSWORD — set the admin password explicitly so the API scripts
# (05, 06, 07) do not fail with 401 on a fresh Grafana instance
# GF_USERS_DEFAULT_LANGUAGE — default UI language for all new users
docker run -d \
  --name=grafana \
  --restart unless-stopped \
  --network=host \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e GF_USERS_DEFAULT_LANGUAGE=ru-RU \
  -v grafana-data:/var/lib/grafana \
  -v grafana-logs:/var/log/grafana \
  -v grafana-config:/etc/grafana \
  grafana/grafana

echo "========================================="
echo "Grafana installation completed"
echo "========================================="

# Verify startup
sleep 5
docker ps | grep grafana

echo "========================================="
echo "Grafana is available at: http://${SERVER_IP}:3000"
echo "Login: admin"
echo "Password: admin"
echo "========================================="