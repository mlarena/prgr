#!/bin/bash

# Скрипт импорта дашборда Node Exporter Full
# Получение IP из файла или автоматическое определение
if [ -f /tmp/server_ip.txt ]; then
    SERVER_IP=$(cat /tmp/server_ip.txt)
else
    SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
fi
echo "========================================="
echo "Импорт дашборда для Node Exporter"
echo "========================================="

# ID дашборда Node Exporter Full (1860)
DASHBOARD_ID="1860"
DASHBOARD_NAME="Node Exporter Full"

# Импорт дашборда Node Exporter Full с grafana.com
echo "Импорт дашборда Node Exporter Full..."
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