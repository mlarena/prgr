#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)
GRAFANA_URL="http://localhost:3000"

echo "========================================="
echo "Настройка источника данных в Grafana"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Ждем полного запуска Grafana (выходим с ошибкой, если не поднялась)
echo "Ожидание запуска Grafana..."
wait_for_url "${GRAFANA_URL}/api/health" "Grafana" 30

# Пароль admin задан при запуске контейнера через GF_SECURITY_ADMIN_PASSWORD (см. 04)

# Проверяем, что datasource еще не добавлен (идемпотентность)
if curl -fsS -u admin:admin "${GRAFANA_URL}/api/datasources/name/Prometheus" > /dev/null 2>&1; then
    echo "Источник данных Prometheus уже существует — пропускаем"
else
    # Добавляем источник данных Prometheus
    curl -fsS -X POST -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -u admin:admin \
      -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://localhost:9090",
        "access": "proxy",
        "basicAuth": false,
        "isDefault": true
      }' \
      "${GRAFANA_URL}/api/datasources" > /dev/null
fi

echo "========================================="
echo "Источник данных Prometheus добавлен"
echo "========================================="