#!/bin/bash

# Скрипт импорта дашборда Node Exporter Full
# IP адрес сервера (замените на ваш IP)
SERVER_IP="192.168.192.141"

echo "========================================="
echo "Импорт дашборда для Node Exporter"
echo "========================================="

# ID дашборда Node Exporter Full (1860)
DASHBOARD_ID="1860"
DASHBOARD_NAME="Node Exporter Full"

# Импорт дашборда через API Grafana
curl -X POST -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "title": "Node Exporter Full",
      "tags": ["node-exporter", "prometheus"],
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0
    },
    "overwrite": true,
    "inputs": [
      {
        "name": "DS_PROMETHEUS",
        "type": "datasource",
        "pluginId": "prometheus",
        "value": "Prometheus"
      }
    ]
  }' \
  http://admin:admin@${SERVER_IP}:3000/api/dashboards/db 2>/dev/null

# Альтернативный способ - импорт через grafana.com
echo "Попытка импорта дашборда с grafana.com..."
curl -X POST -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "dashboard": {
      "id": '${DASHBOARD_ID}'
    },
    "overwrite": true,
    "inputs": [
      {
        "name": "DS_PROMETHEUS",
        "type": "datasource",
        "pluginId": "prometheus",
        "value": "Prometheus"
      }
    ]
  }' \
  http://admin:admin@${SERVER_IP}:3000/api/dashboards/import 2>/dev/null

echo "========================================="
echo "Дашборд импортирован"
echo "========================================="
echo "Grafana: http://${SERVER_IP}:3000"
echo "Логин: admin, Пароль: admin"
echo "Prometheus: http://${SERVER_IP}:9090"
echo "Node Exporter: http://${SERVER_IP}:9100/metrics"
echo "========================================="