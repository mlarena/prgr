#!/bin/bash

# Скрипт установки postgres_exporter для ARM (aarch64/armv7/armv6)
# Пароль вшит прямо в сервисный файл

set -e

echo "========================================="
echo "Установка PostgreSQL Exporter (ARM)"
echo "========================================="

# Определение архитектуры ARM
ARCH=$(uname -m)
case $ARCH in
    aarch64|arm64)
        POSTGRES_EXPORTER_ARCH="linux-arm64"
        echo "Обнаружена архитектура: ARM64 (aarch64)"
        ;;
    armv7l|armhf)
        POSTGRES_EXPORTER_ARCH="linux-armv7"
        echo "Обнаружена архитектура: ARMv7"
        ;;
    armv6l)
        POSTGRES_EXPORTER_ARCH="linux-armv6"
        echo "Обнаружена архитектура: ARMv6"
        ;;
    *)
        echo "Неподдерживаемая архитектура: $ARCH"
        exit 1
        ;;
esac

# Переменные
POSTGRES_EXPORTER_VERSION="0.18.1"
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_DB="postgres"
POSTGRES_USER="postgres_exporter"
POSTGRES_PASSWORD="12345678"

echo "Используется пароль: ${POSTGRES_PASSWORD}"
echo "Сохраните его для настройки PostgreSQL!"

# Скачивание и установка
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${POSTGRES_EXPORTER_ARCH}.tar.gz

# Проверка успешности скачивания
if [ $? -ne 0 ]; then
    echo "Ошибка скачивания PostgreSQL Exporter"
    exit 1
fi

tar -xvf postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${POSTGRES_EXPORTER_ARCH}.tar.gz
sudo cp postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${POSTGRES_EXPORTER_ARCH}/postgres_exporter /usr/local/bin/

# Создание пользователя
sudo useradd --no-create-home --shell /bin/false postgres_exporter 2>/dev/null || true
sudo chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# Создание systemd сервиса с вшитым паролем
sudo tee /etc/systemd/system/postgres_exporter.service << EOF
[Unit]
Description=Prometheus PostgreSQL Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=postgres_exporter
Group=postgres_exporter
Type=simple
Environment="DATA_SOURCE_NAME=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=disable"
ExecStart=/usr/local/bin/postgres_exporter --web.listen-address=:9187
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Запуск сервиса
sudo systemctl daemon-reload
sudo systemctl enable postgres_exporter
sudo systemctl start postgres_exporter

# Очистка
rm -rf /tmp/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${POSTGRES_EXPORTER_ARCH}*
rm -f /tmp/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.${POSTGRES_EXPORTER_ARCH}.tar.gz

echo "========================================="
echo "Установка PostgreSQL Exporter завершена"
echo "========================================="
echo ""
echo "!!! ВАЖНО: Выполните следующие SQL команды в PostgreSQL: !!!"
echo ""
echo "-- Создаем роль для мониторинга"
echo "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}' CONNECTION LIMIT 5;"
echo ""
echo "-- Для PostgreSQL 10+ используем встроенную роль pg_monitor"
echo "GRANT pg_monitor TO ${POSTGRES_USER};"
echo ""
echo "-- Даем права на подключение к базе"
echo "GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"
echo ""
echo "========================================="
echo "Проверка статуса:"
sudo systemctl status postgres_exporter --no-pager

echo ""
echo "Проверка метрик: curl http://localhost:9187/metrics | grep pg_up"