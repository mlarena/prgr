#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)
GRAFANA_URL="http://localhost:3000"

echo "========================================="
echo "Importing Node Exporter dashboard"
echo "========================================="

# Node Exporter Full dashboard ID (1860)
DASHBOARD_ID="1860"
DASHBOARD_JSON="/tmp/dashboard_${DASHBOARD_ID}.json"

# Wait for Grafana to start
echo "Waiting for Grafana to start..."
wait_for_url "${GRAFANA_URL}/api/health" "Grafana" 30

# Download the full dashboard JSON from grafana.com
# (the /api/dashboards/import endpoint expects the full JSON, not just the ID)
echo "Downloading Node Exporter Full dashboard (ID: ${DASHBOARD_ID})..."
curl -fsSL --max-time 30 --retry 2 \
  "https://grafana.com/api/dashboards/${DASHBOARD_ID}/revisions/latest/download" \
  -o "${DASHBOARD_JSON}"

# Null the dashboard id (required for import) and wrap into the API payload format
jq '.id = null' "${DASHBOARD_JSON}" \
  | jq -s '{dashboard: .[0], overwrite: true}' > "${DASHBOARD_JSON}.payload"

# Import the dashboard
echo "Importing dashboard..."
curl -fsS -X POST -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -u admin:admin \
  --data-binary "@${DASHBOARD_JSON}.payload" \
  "${GRAFANA_URL}/api/dashboards/db" > /dev/null

# Clean up temporary files
rm -f "${DASHBOARD_JSON}" "${DASHBOARD_JSON}.payload"

echo "========================================="
echo "Dashboard imported"
echo "========================================="
echo "Grafana: http://${SERVER_IP}:3000"
echo "Login: admin, Password: admin"
echo "Prometheus: http://${SERVER_IP}:9090"
echo "Node Exporter: http://${SERVER_IP}:9100/metrics"
echo "========================================="