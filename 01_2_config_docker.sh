#!/bin/bash
set -euo pipefail

# Docker registry mirrors configuration script (merges into existing daemon.json)

MIRRORS='["https://mirror.gcr.io", "https://dockerhub1.beget.com"]'
DAEMON_JSON="/etc/docker/daemon.json"

mkdir -p /etc/docker

if [ -f "${DAEMON_JSON}" ]; then
    # Merge mirrors into the existing config without overwriting other settings
    jq --argjson mirrors "${MIRRORS}" '."registry-mirrors" = $mirrors' "${DAEMON_JSON}" > "${DAEMON_JSON}.tmp"
else
    jq -n --argjson mirrors "${MIRRORS}" '{"registry-mirrors": $mirrors}' > "${DAEMON_JSON}.tmp"
fi
mv "${DAEMON_JSON}.tmp" "${DAEMON_JSON}"

# Restart Docker
systemctl restart docker

# Print confirmation
echo "Docker mirrors configured successfully!"
echo "Current mirrors:"
docker info | grep -A 3 "Registry Mirrors" || true