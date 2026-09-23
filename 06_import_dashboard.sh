#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)
GRAFANA_URL="http://localhost:3000"

echo "========================================="
echo "Импорт дашборда для Node Exporter"
echo "========================================="

# ID дашборда Node Exporter Full (1860)
DASHBOARD_ID="1860"
DASHBOARD_JSON="/tmp/dashboard_${DASHBOARD_ID}.json"

# Ждем запуска Grafana
echo "Ожидание запуска Grafana..."
wait_for_url "${GRAFANA_URL}/api/health" "Grafana" 30

# Скачиваем полное тело дашборда с grafana.com
# (эндпоинт /api/dashboards/import ожидает полный JSON, а не только ID)
echo "Скачивание дашборда Node Exporter Full (ID: ${DASHBOARD_ID})..."
curl -fsSL --max-time 30 --retry 2 \
  "https://grafana.com/api/dashboards/${DASHBOARD_ID}/revisions/latest/download" \
  -o "${DASHBOARD_JSON}"

# Обнуляем id дашборда (обязательно для импорта) и оборачиваем в формат API
jq '.id = null' "${DASHBOARD_JSON}" \
  | jq -s '{dashboard: .[0], overwrite: true}' > "${DASHBOARD_JSON}.payload"

# Импортируем дашборд
echo "Импорт дашборда..."
curl -fsS -X POST -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -u admin:admin \
  --data-binary "@${DASHBOARD_JSON}.payload" \
  "${GRAFANA_URL}/api/dashboards/db" > /dev/null

# Очистка временных файлов
rm -f "${DASHBOARD_JSON}" "${DASHBOARD_JSON}.payload"

echo "========================================="
echo "Дашборд импортирован"
echo "========================================="
echo "Grafana: http://${SERVER_IP}:3000"
echo "Логин: admin, Пароль: admin"
echo "Prometheus: http://${SERVER_IP}:9090"
echo "Node Exporter: http://${SERVER_IP}:9100/metrics"
echo "========================================="