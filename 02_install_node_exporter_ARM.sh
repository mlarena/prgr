#!/bin/bash

# Получение IP из файла или автоматическое определение
if [ -f /tmp/server_ip.txt ]; then
    SERVER_IP=$(cat /tmp/server_ip.txt)
else
    # Автоматическое определение IP
    SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
fi

echo "========================================="
echo "Установка Node Exporter (ARM)"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Определение архитектуры ARM
ARCH=$(uname -m)
case $ARCH in
    aarch64|arm64)
        NODE_EXPORTER_ARCH="linux-arm64"
        ;;
    armv7l|armhf)
        NODE_EXPORTER_ARCH="linux-armv7"
        ;;
    armv6l)
        NODE_EXPORTER_ARCH="linux-armv6"
        ;;
    *)
        echo "Неподдерживаемая архитектура: $ARCH"
        exit 1
        ;;
esac

echo "Обнаружена архитектура: $ARCH -> $NODE_EXPORTER_ARCH"

# Скачивание последней версии Node Exporter для ARM
NODE_EXPORTER_VERSION="1.10.2"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${NODE_EXPORTER_ARCH}.tar.gz

# Проверка успешности скачивания
if [ $? -ne 0 ]; then
    echo "Ошибка скачивания Node Exporter"
    exit 1
fi

# Распаковка
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.${NODE_EXPORTER_ARCH}.tar.gz

# Копирование бинарного файла в /usr/local/bin
cp node_exporter-${NODE_EXPORTER_VERSION}.${NODE_EXPORTER_ARCH}/node_exporter /usr/local/bin/

# Создание пользователя для node_exporter (если не существует)
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null

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
rm -rf /tmp/node_exporter-${NODE_EXPORTER_VERSION}.${NODE_EXPORTER_ARCH}*
rm -f /tmp/node_exporter-${NODE_EXPORTER_VERSION}.${NODE_EXPORTER_ARCH}.tar.gz

echo "========================================="
echo "Установка Node Exporter завершена"
echo "========================================="

# Проверка статуса
systemctl status node_exporter --no-pager

echo "Node Exporter доступен по адресу: http://${SERVER_IP}:9100/metrics"