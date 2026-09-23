#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)

echo "========================================="
echo "Установка Grafana"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Останавливаем и удаляем старый контейнер если существует
docker stop grafana 2>/dev/null || true
docker rm grafana 2>/dev/null || true

# Загружаем образ Grafana (docker pull идемпотентен)
echo "Загрузка образа Grafana..."
docker pull grafana/grafana

# Запускаем Grafana в Docker
# GF_SECURITY_ADMIN_PASSWORD — задаем пароль admin явно, чтобы API-скрипты
# (05, 06, 07) не упали с 401 на свежей Grafana
# GF_USERS_DEFAULT_LANGUAGE — язык интерфейса по умолчанию для всех новых пользователей
docker run -d \
  --name=grafana \
  --restart unless-stopped \
  --network=host \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e GF_USERS_DEFAULT_LANGUAGE=ru-RU \
  -v grafana-data:/var/lib/grafana \
  -v grafana-logs:/var/log/grafana \
  -v grafana-config:/etc/grafana \
  grafana/grafana

echo "========================================="
echo "Установка Grafana завершена"
echo "========================================="

# Проверяем запуск
sleep 5
docker ps | grep grafana

echo "========================================="
echo "Grafana доступна по адресу: http://${SERVER_IP}:3000"
echo "Логин: admin"
echo "Пароль: admin"
echo "========================================="