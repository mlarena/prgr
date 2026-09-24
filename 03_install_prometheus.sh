#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)

# === Architecture ===
# This script runs on the MONITORING SERVER (Grafana/Prometheus)
# MONITORED_IP — the server to be monitored (node_exporter is installed there)
MONITORED_IP="192.168.192.147"
# ===================

echo "========================================="
echo "Installing Prometheus"
echo "Server IP address: ${SERVER_IP}"
echo "========================================="

# Create the working directory
mkdir -p /monitoring/prometheus

# Create the Prometheus configuration file with automatic IP substitution
cat > /monitoring/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files: []

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Host monitoring via node_exporter (the monitored server)
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['${MONITORED_IP}:9100']
EOF

# Stop and remove the old container if it exists
docker stop prometheus 2>/dev/null || true
docker rm prometheus 2>/dev/null || true

# Pull the Prometheus image (docker pull is idempotent — only missing layers are fetched)
echo "Pulling Prometheus image..."
docker pull prom/prometheus

# Run Prometheus in Docker
docker run -d \
  --name=prometheus \
  --restart unless-stopped \
  --network=host \
  -v /monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v prometheus-data:/prometheus \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus

echo "========================================="
echo "Prometheus installation completed"
echo "========================================="

# Verify startup
sleep 3
docker ps | grep prometheus

echo "Prometheus is available at: http://${SERVER_IP}:9090"
echo "Prometheus Targets: http://${SERVER_IP}:9090/targets"