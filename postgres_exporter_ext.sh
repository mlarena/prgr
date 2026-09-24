#!/bin/bash
set -euo pipefail

# postgres_exporter installation (x86_64 and ARM — single script, architecture is detected automatically)
# Extended variant: enables pg_stat_statements collectors
# The password is embedded directly in the service file

echo "========================================="
echo "Installing PostgreSQL Exporter"
echo "========================================="

# Detect architecture
ARCH=$(uname -m)
case ${ARCH} in
    x86_64|amd64)
        EXPORTER_ARCH="linux-amd64"
        echo "Detected architecture: AMD64 (x86_64)"
        ;;
    aarch64|arm64)
        EXPORTER_ARCH="linux-arm64"
        echo "Detected architecture: ARM64 (aarch64)"
        ;;
    armv7l|armhf)
        EXPORTER_ARCH="linux-armv7"
        echo "Detected architecture: ARMv7"
        ;;
    armv6l)
        EXPORTER_ARCH="linux-armv6"
        echo "Detected architecture: ARMv6"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}" >&2
        exit 1
        ;;
esac

# Variables
POSTGRES_EXPORTER_VERSION="0.18.1"
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_DB="burstroydb"
POSTGRES_USER="user_postgres_exporter"
POSTGRES_PASSWORD="12345678"

echo "Password in use: ${POSTGRES_PASSWORD}"
echo "Save it for the PostgreSQL setup!"

# Download and install
cd /tmp
wget --timeout=30 --tries=3 \
    "https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${EXPORTER_ARCH}.tar.gz"

tar xf "postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${EXPORTER_ARCH}.tar.gz"

install -m 755 "postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${EXPORTER_ARCH}/postgres_exporter" /usr/local/bin/postgres_exporter

# Create the user
useradd --no-create-home --shell /bin/false postgres_exporter 2>/dev/null || true
chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# Create the systemd service with the embedded password
tee /etc/systemd/system/postgres_exporter.service << EOF
[Unit]
Description=Prometheus PostgreSQL Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=postgres_exporter
Group=postgres_exporter
Type=simple
Environment="DATA_SOURCE_NAME=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=disable"
ExecStart=/usr/local/bin/postgres_exporter --web.listen-address=:9187 --collector.stat_statements --collector.stat_statements.include_query --collector.stat_statements.query_length=120
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start the service
systemctl daemon-reload
systemctl enable postgres_exporter
systemctl start postgres_exporter

# Clean up
rm -rf /tmp/postgres_exporter-*

echo "========================================="
echo "PostgreSQL Exporter installation completed"
echo "========================================="
echo ""
echo "!!! IMPORTANT: Run the following SQL commands in PostgreSQL: !!!"
echo ""
echo "-- Create the monitoring role"
echo "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}' CONNECTION LIMIT 5;"
echo ""
echo "-- For PostgreSQL 10+ use the built-in pg_monitor role"
echo "GRANT pg_monitor TO ${POSTGRES_USER};"
echo ""
echo "-- Grant connect access to the database"
echo "GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"
echo ""
echo "========================================="
echo "Status check:"
systemctl status postgres_exporter --no-pager

echo ""
echo "Metrics check: curl http://localhost:9187/metrics | grep pg_up"
