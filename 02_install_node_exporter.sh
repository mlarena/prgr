#!/bin/bash
set -euo pipefail

# Установка Node Exporter (x86_64 и ARM — единый скрипт, архитектура определяется автоматически)

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)

echo "========================================="
echo "Установка Node Exporter"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Определение архитектуры
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
        echo "Неподдерживаемая архитектура: ${ARCH}" >&2
        exit 1
        ;;
esac

# Версия: последняя с GitHub API, при недоступности — фиксированный fallback
NODE_EXPORTER_VERSION="$(get_latest_release "prometheus/node_exporter" "1.10.2")"

echo "Обнаружена архитектура: ${ARCH} -> ${EXPORTER_ARCH}"
echo "Версия Node Exporter: ${NODE_EXPORTER_VERSION}"

# Скачивание и распаковка
cd /tmp
wget --timeout=30 --tries=3 \
    "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${EXPORTER_ARCH}.tar.gz"

tar xf "node_exporter-${NODE_EXPORTER_VERSION}.${EXPORTER_ARCH}.tar.gz"

# Копирование бинарного файла в /usr/local/bin
install -m 755 "node_exporter-${NODE_EXPORTER_VERSION}.${EXPORTER_ARCH}/node_exporter" /usr/local/bin/node_exporter

# Создание пользователя для node_exporter (если не существует)
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

# Создание systemd сервиса
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

# Создание директории для текстовых метрик
mkdir -p /var/lib/node_exporter/textfile_collector
chown -R node_exporter:node_exporter /var/lib/node_exporter

# Запуск сервиса
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Очистка временных файлов
rm -rf /tmp/node_exporter-*

echo "========================================="
echo "Установка Node Exporter завершена"
echo "========================================="

# Проверка статуса
systemctl status node_exporter --no-pager

echo "Node Exporter доступен по адресу: http://${SERVER_IP}:9100/metrics"
