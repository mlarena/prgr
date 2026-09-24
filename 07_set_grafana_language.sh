#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)
GRAFANA_URL="http://localhost:3000"

echo "========================================="
echo "Setting Russian language in Grafana"
echo "Grafana URL: http://${SERVER_IP}:3000"
echo "========================================="

# Wait for Grafana to start (exit with error if it never comes up)
echo "Waiting for Grafana to start..."
wait_for_url "${GRAFANA_URL}/api/health" "Grafana" 30

# The default language for all NEW users is set globally
# via GF_USERS_DEFAULT_LANGUAGE=ru-RU at container startup (see 04_install_grafana.sh)
# Here we additionally set the locale for the existing admin user
echo "Setting Russian language for the admin user..."
curl -fsS -X PUT -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{"locale":"ru-RU"}' \
  "${GRAFANA_URL}/api/user/preferences" > /dev/null

echo "========================================="
echo "Russian language set!"
echo ""
echo "Notes:"
echo "- Default language for new users is configured in 04_install_grafana.sh"
echo "- locale affects date/number formatting; full Grafana UI localization is limited"
echo "- Reload the Grafana page (F5 or Ctrl+R) to apply the changes"
echo "Grafana: http://${SERVER_IP}:3000"
echo "Login: admin, Password: admin"
echo "========================================="