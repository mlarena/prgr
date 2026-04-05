#!/bin/bash

# Получение IP из файла или автоматическое определение
if [ -f /tmp/server_ip.txt ]; then
    SERVER_IP=$(cat /tmp/server_ip.txt)
else
    SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
fi

echo "========================================="
echo "Установка Grafana"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Останавливаем и удаляем старый контейнер если существует
docker stop grafana 2>/dev/null
docker rm grafana 2>/dev/null

# Загружаем образ Grafana (если еще нет)
echo "Проверка наличия образа Grafana..."
if ! docker images grafana/grafana --format "{{.Repository}}" | grep -q grafana/grafana; then
    echo "Загрузка образа Grafana..."
    docker pull grafana/grafana
else
    echo "Образ Grafana уже загружен"
fi

# Запускаем Grafana в Docker
docker run -d \
  --name=grafana \
  --restart unless-stopped \
  --network=host \
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