#!/bin/bash

# Скрипт для установки русского языка в Grafana
# Получение IP из файла или автоматическое определение
if [ -f /tmp/server_ip.txt ]; then
    SERVER_IP=$(cat /tmp/server_ip.txt)
else
    SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
fi

echo "========================================="
echo "Настройка русского языка в Grafana"
echo "Grafana URL: http://${SERVER_IP}:3000"
echo "========================================="

# Ждем запуска Grafana
echo "Ожидание запуска Grafana..."
for i in {1..30}; do
    if curl -s "http://${SERVER_IP}:3000/api/health" > /dev/null 2>&1; then
        echo "Grafana готова к работе"
        break
    fi
    echo "Ожидание Grafana... ($i/30)"
    sleep 2
done

# Устанавливаем русский язык
echo "Установка русского языка..."
curl -X PUT -H "Content-Type: application/json" \
  -d '{"locale":"ru-RU"}' \
  http://admin:admin@${SERVER_IP}:3000/api/user/preferences 2>/dev/null

echo "========================================="
echo "Русский язык установлен!"
echo "Для применения изменений обновите страницу Grafana (F5 или Ctrl+R)"
echo "Grafana: http://${SERVER_IP}:3000"
echo "Логин: admin, Пароль: admin"
echo "========================================="