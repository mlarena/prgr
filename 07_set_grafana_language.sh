#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SERVER_IP=$(detect_server_ip)
GRAFANA_URL="http://localhost:3000"

echo "========================================="
echo "Настройка русского языка в Grafana"
echo "Grafana URL: http://${SERVER_IP}:3000"
echo "========================================="

# Ждем запуска Grafana (выходим с ошибкой, если не поднялась)
echo "Ожидание запуска Grafana..."
wait_for_url "${GRAFANA_URL}/api/health" "Grafana" 30

# Язык по умолчанию для всех НОВЫХ пользователей задается глобально
# через GF_USERS_DEFAULT_LANGUAGE=ru-RU при запуске контейнера (см. 04_install_grafana.sh)
# Здесь дополнительно выставляем локаль для существующего пользователя admin
echo "Установка русского языка для пользователя admin..."
curl -fsS -X PUT -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{"locale":"ru-RU"}' \
  "${GRAFANA_URL}/api/user/preferences" > /dev/null

echo "========================================="
echo "Русский язык установлен!"
echo ""
echo "Примечания:"
echo "- Для новых пользователей язык по умолчанию задан в 04_install_grafana.sh"
echo "- locale влияет на формат дат и чисел; полная локализация интерфейса Grafana ограничена"
echo "- Для применения изменений обновите страницу Grafana (F5 или Ctrl+R)"
echo "Grafana: http://${SERVER_IP}:3000"
echo "Логин: admin, Пароль: admin"
echo "========================================="