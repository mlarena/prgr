#!/bin/bash
set -euo pipefail

# Node Exporter installation (x86_64 and ARM — single script, architecture is detected automatically)

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)

echo "========================================="
echo "Installing Node Exporter"
echo "Server IP address: ${SERVER_IP}"
echo "========================================="

# Detect architecture
ARCH=$(uname -m)
case ${ARCH} in
    x86_64|amd64)
        EXPORTER_ARCH="linux-amd64"
        ;;
    aarch64|arm64)
        EXPORTER_ARCH="linux-arm64"
        ;;
    armv7l|armhf)
        EXPORTER_ARCH="linux-armv7"
        ;;
    armv6l)
        EXPORTER_ARCH="linux-armv6"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}" >&2
        exit 1
        ;;
esac

# Version: latest from the GitHub API, fixed fallback if the API is unreachable
NODE_EXPORTER_VERSION="$(get_latest_release "prometheus/node_exporter" "1.10.2")"

echo "Detected architecture: ${ARCH} -> ${EXPORTER_ARCH}"
echo "Node Exporter version: ${NODE_EXPORTER_VERSION}"

# Download and unpack
cd /tmp
wget --timeout=30 --tries=3 \
    "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${EXPORTER_ARCH}.tar.gz"

tar xf "node_exporter-${NODE_EXPORTER_VERSION}.${EXPORTER_ARCH}.tar.gz"

# Copy the binary to /usr/local/bin
install -m 755 "node_exporter-${NODE_EXPORTER_VERSION}.${EXPORTER_ARCH}/node_exporter" /usr/local/bin/node_exporter

# Create the node_exporter user (if it does not exist)
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

# Create the systemd service
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --web.listen-address=:9100 \
    --collector.textfile.directory=/var/lib/node_exporter/textfile_collector

[Install]
WantedBy=multi-user.target
EOF

# Create the textfile metrics directory
mkdir -p /var/lib/node_exporter/textfile_collector
chown -R node_exporter:node_exporter /var/lib/node_exporter

# Start the service
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Clean up temporary files
rm -rf /tmp/node_exporter-*

echo "========================================="
echo "Node Exporter installation completed"
echo "========================================="

# Check status
systemctl status node_exporter --no-pager

echo "Node Exporter is available at: http://${SERVER_IP}:9100/metrics"
