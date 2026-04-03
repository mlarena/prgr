#!/bin/bash

# Получение IP из файла или автоматическое определение
if [ -f /tmp/server_ip.txt ]; then
    SERVER_IP=$(cat /tmp/server_ip.txt)
else
    SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
fi

echo "========================================="
echo "Настройка источника данных в Grafana"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Ждем полного запуска Grafana
echo "Ожидание запуска Grafana..."
sleep 15

# Проверяем доступность Grafana
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s "http://${SERVER_IP}:3000/api/health" > /dev/null 2>&1; then
        echo "Grafana готова к работе"
        break
    fi
    echo "Ожидание Grafana... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done
# Настройка источника данных через API Grafana
# Сначала меняем пароль admin по умолчанию (оставляем admin/admin для простоты)
curl -s -X PUT -H "Content-Type: application/json" \
  -d '{"password":"admin","oldPassword":"admin"}' \
  http://admin:admin@localhost:3000/api/user/password > /dev/null# Добавляем источник данных Prometheus
curl -s -X POST -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://'${SERVER_IP}':9090",
    "access": "proxy",
    "basicAuth": false,
    "isDefault": true
  }' \
  http://admin:admin@${SERVER_IP}:3000/api/datasources > /dev/null
echo "========================================="
echo "Источник данных Prometheus добавлен"
echo "========================================="