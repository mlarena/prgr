#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)
GRAFANA_URL="http://localhost:3000"

echo "========================================="
echo "Configuring Grafana datasource"
echo "Server IP address: ${SERVER_IP}"
echo "========================================="

# Wait for Grafana to fully start (exit with error if it never comes up)
echo "Waiting for Grafana to start..."
wait_for_url "${GRAFANA_URL}/api/health" "Grafana" 30

# The admin password is set at container startup via GF_SECURITY_ADMIN_PASSWORD (see 04)

# Check that the datasource does not exist yet (idempotency)
if curl -fsS -u admin:admin "${GRAFANA_URL}/api/datasources/name/Prometheus" > /dev/null 2>&1; then
    echo "Prometheus datasource already exists — skipping"
else
    # Add the Prometheus datasource
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
echo "Prometheus datasource added"
echo "========================================="