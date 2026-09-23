#!/bin/bash
set -euo pipefail

# Скрипт настройки зеркал Docker (мержится в существующий daemon.json)

MIRRORS='["https://mirror.gcr.io", "https://dockerhub1.beget.com"]'
DAEMON_JSON="/etc/docker/daemon.json"

mkdir -p /etc/docker

if [ -f "${DAEMON_JSON}" ]; then
    # Мержим зеркала в существующий конфиг, не затирая остальные настройки
    jq --argjson mirrors "${MIRRORS}" '."registry-mirrors" = $mirrors' "${DAEMON_JSON}" > "${DAEMON_JSON}.tmp"
else
    jq -n --argjson mirrors "${MIRRORS}" '{"registry-mirrors": $mirrors}' > "${DAEMON_JSON}.tmp"
fi
mv "${DAEMON_JSON}.tmp" "${DAEMON_JSON}"

# Перезапуск Docker
systemctl restart docker

# Вывод подтверждения
echo "Docker mirrors configured successfully!"
echo "Current mirrors:"
docker info | grep -A 3 "Registry Mirrors" || true